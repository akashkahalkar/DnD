import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Interface for Apple Foundation Models (Mock for now)
protocol AIClientProtocol {
    func generateStory(prompt: String) async throws -> StoryResponse
    func resetSession()
}

enum LLMError: Error {
    case modelUnavailable
    case invalidResponse
    case decodingError(String)
}

class LLMClient: AIClientProtocol {
    
    private var session: Any? // Will be LanguageModelSession on iOS 26+
    
    func resetSession() {
        session = nil
        StartupDiagnostics.mark("AI session reset")
    }
    
    func generateStory(prompt: String) async throws -> StoryResponse {
        let requestStart = ProcessInfo.processInfo.systemUptime
        StartupDiagnostics.mark("generateStory called")
        // Check if Foundation Models are available (iOS 26+)
        if #available(iOS 26.0, *) {
            #if canImport(FoundationModels)
            StartupDiagnostics.mark("generateStory using Foundation Model")
            let response = try await generateWithFoundationModel(prompt: prompt)
            let elapsed = ProcessInfo.processInfo.systemUptime - requestStart
            let formatted = String(format: "%.3f", elapsed)
            StartupDiagnostics.mark("generateStory finished in \(formatted)s")
            return response
            #else
            StartupDiagnostics.mark("generateStory using mock response (FoundationModels unavailable at compile time)")
            let response = try await generateMockStory(prompt: prompt)
            let elapsed = ProcessInfo.processInfo.systemUptime - requestStart
            let formatted = String(format: "%.3f", elapsed)
            StartupDiagnostics.mark("generateStory finished in \(formatted)s")
            return response
            #endif
        } else {
            // Fallback to mock for older iOS versions
            StartupDiagnostics.mark("generateStory using mock response (iOS < 26)")
            let response = try await generateMockStory(prompt: prompt)
            let elapsed = ProcessInfo.processInfo.systemUptime - requestStart
            let formatted = String(format: "%.3f", elapsed)
            StartupDiagnostics.mark("generateStory finished in \(formatted)s")
            return response
        }
    }
    
    // MARK: - Foundation Model Implementation (iOS 26+)
    
    @available(iOS 26.0, *)
    private func generateWithFoundationModel(prompt: String) async throws -> StoryResponse {
        #if canImport(FoundationModels)
        let operationStart = ProcessInfo.processInfo.systemUptime
        StartupDiagnostics.mark("Foundation model generation started")
        do {
            // Access the system language model
            let model = SystemLanguageModel()
            
            // Create or reuse session for conversation context
            if session == nil {
                session = LanguageModelSession(model: model)
            }
            
            guard let languageSession = session as? LanguageModelSession else {
                throw LLMError.modelUnavailable
            }
            
            // Build the full prompt with system instructions and JSON schema
            let fullPrompt = buildDungeonMasterPrompt(userPrompt: prompt)
            
            
            // Generate response with guided output
            let response = try await languageSession.respond(to: fullPrompt)
            
            // Parse the response as JSON
            guard let jsonData = response.content.data(using: .utf8) else {
                throw LLMError.invalidResponse
            }
            do {
                let storyResponse = try JSONDecoder().decode(StoryResponse.self, from: jsonData)
                let elapsed = ProcessInfo.processInfo.systemUptime - operationStart
                let formatted = String(format: "%.3f", elapsed)
                StartupDiagnostics.mark("Foundation model generation decoded in \(formatted)s")
                return storyResponse
            } catch {
                // If JSON parsing fails, try to extract JSON from markdown code blocks
                let cleanedJSON = extractJSON(from: response.content)
                guard let cleanedData = cleanedJSON.data(using: .utf8) else {
                    throw LLMError.decodingError("Could not extract valid JSON from response")
                }
                let storyResponse = try JSONDecoder().decode(StoryResponse.self, from: cleanedData)
                let elapsed = ProcessInfo.processInfo.systemUptime - operationStart
                let formatted = String(format: "%.3f", elapsed)
                StartupDiagnostics.mark("Foundation model generation decoded after cleanup in \(formatted)s")
                return storyResponse
            }
        } catch {
            StartupDiagnostics.mark("Foundation model error: \(error.localizedDescription). Falling back to mock")
            return try await generateMockStory(prompt: prompt)
        }
        #else
        return try await generateMockStory(prompt: prompt)
        #endif
    }
    
    // MARK: - Helper Methods
    
    private func buildDungeonMasterPrompt(userPrompt: String) -> String {
        return """
        You are an expert Dungeon Master for a dark fantasy RPG in the style of Dungeons & Dragons.
        Your role is to create immersive, atmospheric narrative experiences.
        
        CRITICAL: You MUST respond with ONLY valid JSON matching this exact schema:
        {
          "scene_description": "A vivid description of the current scene (2-3 sentences)",
          "npc_dialogue": [
            {
              "speaker": "NPC Name",
              "line": "What the NPC says"
            }
          ],
          "choices": [
            "First player choice",
            "Second player choice",
            "Third player choice"
          ],
          "requires_roll": "ability_name or null"
        
        }
        
        Rules:
        - scene_description: Atmospheric, sensory-rich description
        - npc_dialogue: Array of 0-2 NPC dialogue objects (can be empty)
        - choices: Exactly 3 meaningful player choices
        - requires_roll: One of ["strength", "dexterity", "constitution", "intelligence", "wisdom", "charisma", null]
        - IMPORTANT: Prefer deterministic storytelling. Set requires_roll to null by default.
        - Roll frequency target: roughly 1 roll every 3-4 scenes, not every scene.
        - Respect scene turn context provided in User Context.
        - If scene turn number is 1, requires_roll should be null unless there is an exceptional immediate high-stakes event.
        - Use a roll ONLY when all are true:
          1) The action is uncertain,
          2) Failure has meaningful consequences,
          3) The moment is high-stakes or dramatic.
        - No roll if: action is routine, exploratory, conversational, low-stakes, or can be reasonably resolved by narration.
        - If unsure, choose null.
        - The opening scene should almost always use requires_roll: null.
        - Use dark fantasy tone, tactical choices, and mythical elements
        - Keep descriptions concise but evocative
        
        User Context:
        \(userPrompt)
        
        Respond with ONLY the JSON object, no additional text or markdown formatting.
        """
    }
    
    private func extractJSON(from text: String) -> String {
        // Try to extract JSON from markdown code blocks
        if let range = text.range(of: "```json\\s*\\n", options: .regularExpression) {
            var jsonText = String(text[range.upperBound...])
            if let endRange = jsonText.range(of: "```") {
                jsonText = String(jsonText[..<endRange.lowerBound])
            }
            return jsonText.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Try to find raw JSON object
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            return String(text[startIndex...endIndex])
        }
        
        return text
    }
    
    // MARK: - Mock Implementation (Fallback)
    
    private func generateMockStory(prompt: String) async throws -> StoryResponse {
        let operationStart = ProcessInfo.processInfo.systemUptime
        StartupDiagnostics.mark("Mock story generation started")
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Return varied mock responses based on prompt content
        let result: StoryResponse
        if prompt.lowercased().contains("start") || prompt.lowercased().contains("new") {
            result = mockStartingScene()
        } else if prompt.lowercased().contains("attack") || prompt.lowercased().contains("fight") {
            result = mockCombatScene()
        } else {
            result = mockExplorationScene()
        }
        let elapsed = ProcessInfo.processInfo.systemUptime - operationStart
        let formatted = String(format: "%.3f", elapsed)
        StartupDiagnostics.mark("Mock story generation finished in \(formatted)s")
        return result
    }
    
    private func mockStartingScene() -> StoryResponse {
        let mockJSON = """
        {
          "scene_description": "You awaken in a dimly lit tavern called The Gilded Griffin. Rain hammers against the windows as a hooded figure approaches your table, sliding a sealed letter across the worn wood.",
          "npc_dialogue": [
            {
              "speaker": "Hooded Stranger",
              "line": "The Council of Mages seeks adventurers brave enough to enter the Shadowfen Ruins. Are you interested?"
            }
          ],
          "choices": [
            "Accept the mysterious quest",
            "Demand more information about the ruins",
            "Politely decline and order another drink"
          ],
          "requires_roll": null
        }
        """
        
        let data = mockJSON.data(using: .utf8)!
        return try! JSONDecoder().decode(StoryResponse.self, from: data)
    }
    
    private func mockCombatScene() -> StoryResponse {
        let mockJSON = """
        {
          "scene_description": "The ancient dragon's scales shimmer like molten gold in the cavern's ethereal light. Its eyes lock onto you as smoke curls from its nostrils. The ground trembles with each breath.",
          "npc_dialogue": [
            {
              "speaker": "Kael the Ranger",
              "line": "Steady now. One wrong move and we're ash. I'll flank left if you can hold its attention."
            }
          ],
          "choices": [
            "Cast a defensive spell and prepare for its breath attack",
            "Attempt to reason with the ancient creature",
            "Signal Kael and coordinate a simultaneous strike"
          ],
          "requires_roll": "charisma"
        }
        """
        
        let data = mockJSON.data(using: .utf8)!
        return try! JSONDecoder().decode(StoryResponse.self, from: data)
    }
    
    private func mockExplorationScene() -> StoryResponse {
        let mockJSON = """
        {
          "scene_description": "The corridor opens into a vast chamber filled with crystalline formations that pulse with an otherworldly blue light. Ancient runes cover the walls, and you hear the distant sound of running water.",
          "npc_dialogue": [],
          "choices": [
            "Examine the glowing crystals more closely",
            "Attempt to decipher the ancient runes",
            "Follow the sound of water deeper into the chamber"
          ],
          "requires_roll": "intelligence"
        }
        """
        
        let data = mockJSON.data(using: .utf8)!
        return try! JSONDecoder().decode(StoryResponse.self, from: data)
    }
}
