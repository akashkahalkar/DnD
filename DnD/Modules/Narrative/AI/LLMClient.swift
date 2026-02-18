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

@available(iOS 26.0, *)
class LLMClient: AIClientProtocol {
    static let shared = LLMClient()

    private var session: LanguageModelSession? // Will be LanguageModelSession on iOS 26+

    func resetSession() {
        session = nil
        StartupDiagnostics.mark("AI session reset")
    }

    func generateCampaignSeeds(count: Int = 6) async -> [String] {
        let fallback = fallbackCampaignSeeds()
#if canImport(FoundationModels)
        if #available(iOS 26.0, *), !isLocaleSupported() {
            StartupDiagnostics.mark("Campaign seed generation skipped: unsupported language/locale")
            return Array(fallback.prefix(count))
        }
        do {
            let model = SystemLanguageModel()
            let localSession = LanguageModelSession(
                model: model,
                instructions: """
                    Generate concise dark-fantasy campaign seed titles.
                    Return short titles only.
                    """
            )

            let response: LanguageModelSession.Response<GuidedCampaignSeeds> = try await localSession.respond(
                to: "Generate exactly \(count) unique campaign seed titles.",
                generating: GuidedCampaignSeeds.self,
                includeSchemaInPrompt: true
            )

            let cleaned = response.content.seeds
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            if cleaned.count >= count {
                return Array(cleaned.prefix(count))
            }
        } catch {
            StartupDiagnostics.mark("Campaign seed generation failed: \(error.localizedDescription)")
        }
#endif

        return Array(fallback.prefix(count))
    }
    
    func generateStory(prompt: String) async throws -> StoryResponse {
        let requestStart = ProcessInfo.processInfo.systemUptime
        StartupDiagnostics.mark("generateStory called")
        logLocaleDiagnostics(prompt: prompt, label: "generateStory")
            // Check if Foundation Models are available (iOS 26+)
#if canImport(FoundationModels)
        if #available(iOS 26.0, *), !isLocaleSupported() {
            StartupDiagnostics.mark("Foundation model skipped: unsupported language/locale")
            let response = try await generateMockStory(prompt: prompt)
            let elapsed = ProcessInfo.processInfo.systemUptime - requestStart
            let formatted = String(format: "%.3f", elapsed)
            StartupDiagnostics.mark("generateStory finished in \(formatted)s")
            return response
        }
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
        
    }
    
    // MARK: - Foundation Model Implementation (iOS 26+)
    
    private func generateWithFoundationModel(prompt: String) async throws -> StoryResponse {
        #if canImport(FoundationModels)
        let startTime = ProcessInfo.processInfo.systemUptime
        StartupDiagnostics.mark("Foundation model generation started")

        do {
            let model = SystemLanguageModel()

            // 1. Ensure session exists
            if session == nil {
                session = LanguageModelSession(model: model, instructions: buildDungeonMasterInstructions())
            }

            guard let currentSession = session else { throw LLMError.modelUnavailable }

            // 2. Define a reusable generation closure to avoid repetition
            let performGeneration = { (targetSession: LanguageModelSession) async throws -> LanguageModelSession.Response<GuidedStoryResponse> in
                return try await targetSession.respond(
                    to: prompt,
                    generating: GuidedStoryResponse.self,
                    options: GenerationOptions(temperature: 0.6)
                )
            }

            let response: LanguageModelSession.Response<GuidedStoryResponse>
            do {
                response = try await performGeneration(currentSession)
            } catch let error as LanguageModelSession.GenerationError {
                response = try await handleGenerationError(error, model: model, prompt: prompt, originalSession: currentSession, retryAction: performGeneration)
            }

            let elapsed = String(format: "%.3f", ProcessInfo.processInfo.systemUptime - startTime)
            StartupDiagnostics.mark("Foundation model guided generation completed in \(elapsed)s")

            return response.content.toStoryResponse()

        } catch {
            StartupDiagnostics.mark("Foundation model error: \(error.localizedDescription). Falling back to mock")
            return try await generateMockStory(prompt: prompt)
        }
        #else
        return try await generateMockStory(prompt: prompt)
        #endif
    }

    /// Helper to handle context window issues specifically
    private func handleGenerationError(
        _ error: LanguageModelSession.GenerationError,
        model: SystemLanguageModel,
        prompt: String,
        originalSession: LanguageModelSession,
        retryAction: (LanguageModelSession) async throws -> LanguageModelSession.Response<GuidedStoryResponse>
    ) async throws -> LanguageModelSession.Response<GuidedStoryResponse> {

        switch error {
        case .exceededContextWindowSize:
            StartupDiagnostics.mark("Context window exceeded. Attempting trim...")

            // Attempt 1: Trim partially
            let trimmed = rebuildSessionWithTrimmedTranscript(from: originalSession, model: model, keepRecentNonInstructionEntries: 4)
            self.session = trimmed

            do {
                return try await retryAction(trimmed)
            } catch {
                StartupDiagnostics.mark("Context still exceeded. Performing total reset.")
                // Attempt 2: Total Reset
                let reset = rebuildSessionWithTrimmedTranscript(from: originalSession, model: model, keepRecentNonInstructionEntries: 0)
                self.session = reset
                return try await retryAction(reset)
            }

        case .unsupportedLanguageOrLocale:
            throw error // Caught by the outer block to trigger mock
        default:
            throw error
        }
    }

    // MARK: - Helper Methods
    
    private func buildDungeonMasterInstructions() -> String {
        """
        You are a dark-fantasy dungeon master. Keep output short.
        - Always return exactly 3 choices.
        - Set correct_choice_index to 1 or 2 or 3.
        - Include quest_goal on quest start and keep it consistent.
        - quest_outcome must be one of: in_progress, success, failure.
        - Keep scene_description short and focused on the current step.
        """
    }

    @available(iOS 26.0, *)
    func prewarmStorySession(promptPrefix: String) async {
        #if canImport(FoundationModels)
        if !isLocaleSupported() {
            StartupDiagnostics.mark("Prewarm skipped: unsupported language/locale")
            return
        }
        let model = SystemLanguageModel()
        if session == nil {
            session = LanguageModelSession(
                model: model,
                instructions: buildDungeonMasterInstructions()
            )
        }
        
        let prompt = Prompt(promptPrefix)
        session?.prewarm(promptPrefix: prompt)
        StartupDiagnostics.mark("Foundation model session prewarmed")

        #endif
    }

    @available(iOS 26.0, *)
    private func isLocaleSupported() -> Bool {
        #if canImport(FoundationModels)
        let supportedLanguages = SystemLanguageModel.default.supportedLanguages
        return supportedLanguages.contains(Locale.current.language)
        #else
        return false
        #endif
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

    private func logLocaleDiagnostics(prompt: String, label: String) {
        let localeId = Locale.current.identifier
        let language = Locale.current.language
        let hasNonASCII = prompt.unicodeScalars.contains { $0.value > 127 }
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let head = String(trimmed.prefix(180))
        let tail = String(trimmed.suffix(180))
        StartupDiagnostics.mark(
            "LocaleDiag[\(label)] locale=\(localeId), language=\(language), nonASCII=\(hasNonASCII), prompt_head=\(head)"
        )
        if tail != head {
            StartupDiagnostics.mark("LocaleDiag[\(label)] prompt_tail=\(tail)")
        }
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

    private func fallbackCampaignSeeds() -> [String] {
        [
            "Crimson Eclipse",
            "Thornbound Oath",
            "Ashen Crown",
            "Veil of Cinders",
            "Frostbound Sigil",
            "Hollow Star"
        ]
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
            "Politely decline and order another drink"
          ],
          "quest_goal": "Enter Shadowfen Ruins and retrieve the council seal.",
          "correct_choice_index": 1,
          "requires_roll": null,
          "is_combat": false,
          "quest_outcome": "in_progress"
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
            "Signal Kael and coordinate a simultaneous strike"
          ],
          "quest_goal": "Survive the dragon and seize the ember relic.",
          "correct_choice_index": 2,
          "requires_roll": "charisma",
          "is_combat": true,
          "quest_outcome": "in_progress"
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
            "Follow the sound of water deeper into the chamber"
          ],
          "quest_goal": "Find the hidden spring and secure the moon key.",
          "correct_choice_index": 1,
          "requires_roll": "intelligence",
          "is_combat": false,
          "quest_outcome": "in_progress"
        }
        """
        
        let data = mockJSON.data(using: .utf8)!
        return try! JSONDecoder().decode(StoryResponse.self, from: data)
    }
}
