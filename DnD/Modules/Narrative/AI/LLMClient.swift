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
                session = LanguageModelSession(
                    model: model,
                    instructions: buildDungeonMasterInstructions()
                )
            }
            
            guard let languageSession = session as? LanguageModelSession else {
                throw LLMError.modelUnavailable
            }
            
            // Prompt carries per-turn context; session instructions define global behavior.
            let fullPrompt = buildDungeonMasterPrompt(userPrompt: prompt)
            
            let response: LanguageModelSession.Response<GuidedStoryResponse>
            do {
                response = try await languageSession.respond(
                    to: fullPrompt,
                    generating: GuidedStoryResponse.self,
                    includeSchemaInPrompt: true
                )
            } catch let generationError as LanguageModelSession.GenerationError {
                switch generationError {
                case .exceededContextWindowSize(let context):
                    StartupDiagnostics.mark("Foundation model context window exceeded: \(context.debugDescription)")
                    logTranscriptDiagnostics(languageSession.transcript, label: "before trim")
                    
                    let trimmedSession = rebuildSessionWithTrimmedTranscript(
                        from: languageSession,
                        model: model,
                        keepRecentNonInstructionEntries: 4
                    )
                    session = trimmedSession
                    logTranscriptDiagnostics(trimmedSession.transcript, label: "after trim")
                    
                    do {
                        response = try await trimmedSession.respond(
                            to: fullPrompt,
                            generating: GuidedStoryResponse.self,
                            includeSchemaInPrompt: true
                        )
                    } catch {
                        // If still failing, try a total reset (instructions only)
                        StartupDiagnostics.mark("Context window still exceeded after trim. Total reset.")
                        let resetSession = rebuildSessionWithTrimmedTranscript(
                            from: languageSession,
                            model: model,
                            keepRecentNonInstructionEntries: 0
                        )
                        session = resetSession
                        response = try await resetSession.respond(
                            to: fullPrompt,
                            generating: GuidedStoryResponse.self,
                            includeSchemaInPrompt: true
                        )
                    }
                default:
                    throw generationError
                }
            }
            
            let storyResponse = response.content.toStoryResponse()
            let elapsed = ProcessInfo.processInfo.systemUptime - operationStart
            let formatted = String(format: "%.3f", elapsed)
            StartupDiagnostics.mark("Foundation model guided generation completed in \(formatted)s")
            return storyResponse
        } catch {
            StartupDiagnostics.mark("Foundation model error: \(error.localizedDescription). Falling back to mock")
            return try await generateMockStory(prompt: prompt)
        }
        #else
        return try await generateMockStory(prompt: prompt)
        #endif
    }
    
    // MARK: - Helper Methods
    
    private func buildDungeonMasterInstructions() -> String {
        """
        Expert DM for dark-fantasy RPG. Session is exactly 8 turns.
        - Give 3 choices.
        - requires_roll: nil by default. Use only for high stakes.
        - Turn 7: FORCE a confrontation (is_combat=true). Use ambushes for cautious players.
        - quest_outcome: Set 'success' or 'failure' at turn 8 based on story logic.
        - Tone: Atmospheric, tactical.
        """
    }
    
    private func buildDungeonMasterPrompt(userPrompt: String) -> String {
        return """
        Generate the next story scene using this current game context:
        \(userPrompt)
        """
    }
    
    @available(iOS 26.0, *)
    private func rebuildSessionWithTrimmedTranscript(
        from currentSession: LanguageModelSession,
        model: SystemLanguageModel,
        keepRecentNonInstructionEntries: Int = 4
    ) -> LanguageModelSession {
        let allEntries = Array(currentSession.transcript)
        let instructionEntry = allEntries.last(where: { entry in
            if case .instructions = entry { return true }
            return false
        })
        
        let nonInstructionEntries = allEntries.filter { entry in
            if case .instructions = entry { return false }
            return true
        }
        
        var rebuiltEntries: [Transcript.Entry] = []
        if let instructionEntry {
            rebuiltEntries.append(instructionEntry)
        } else {
            // Fallback safeguard: preserve base instructions if transcript has no instruction entry.
            rebuiltEntries.append(
                .instructions(
                    Transcript.Instructions(
                        segments: [.text(.init(content: buildDungeonMasterInstructions()))],
                        toolDefinitions: []
                    )
                )
            )
        }
        
        rebuiltEntries.append(contentsOf: nonInstructionEntries.suffix(keepRecentNonInstructionEntries))
        let trimmedTranscript = Transcript(entries: rebuiltEntries)
        
        return LanguageModelSession(model: model, transcript: trimmedTranscript)
    }
    
    @available(iOS 26.0, *)
    private func logTranscriptDiagnostics(_ transcript: Transcript, label: String) {
        var instructionCount = 0
        var promptCount = 0
        var responseCount = 0
        var toolCallCount = 0
        var toolOutputCount = 0
        var approxCharCount = 0
        
        for entry in transcript {
            let description = String(describing: entry)
            approxCharCount += description.count
            
            switch entry {
            case .instructions:
                instructionCount += 1
            case .prompt:
                promptCount += 1
            case .response:
                responseCount += 1
            case .toolCalls:
                toolCallCount += 1
            case .toolOutput:
                toolOutputCount += 1
            @unknown default:
                fatalError()
            }
        }
        
        StartupDiagnostics.mark(
            "Transcript \(label): entries=\(transcript.count), approxChars=\(approxCharCount), instructions=\(instructionCount), prompts=\(promptCount), responses=\(responseCount), toolCalls=\(toolCallCount), toolOutput=\(toolOutputCount)"
        )
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
          "requires_roll": null,
          "is_combat": false
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
          "requires_roll": "charisma",
          "is_combat": true
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
          "requires_roll": "intelligence",
          "is_combat": false
        }
        """
        
        let data = mockJSON.data(using: .utf8)!
        return try! JSONDecoder().decode(StoryResponse.self, from: data)
    }
}
