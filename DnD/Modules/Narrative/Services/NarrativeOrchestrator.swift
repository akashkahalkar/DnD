import Foundation

class NarrativeOrchestrator {
    private let aiClient: AIClientProtocol
    private(set) var currentStory: StoryResponse?
    
    init(aiClient: AIClientProtocol = LLMClient()) {
        self.aiClient = aiClient
    }
    
    func startNewGame(player: Player, turnNumber: Int = 1) async throws -> StoryResponse {
        aiClient.resetSession()
        
        let basePrompt = """
        GAME_CONTEXT
        - session_phase: opening_scene
        \(buildPlayerContext(player: player))
        - turn_number: \(turnNumber)
        - target_session_length_turns: 10-15
        - previous_scene: none
        - previous_choice: none
        
        TASK
        - Start a new dark-fantasy adventure.
        """
        
        let response = try await aiClient.generateStory(prompt: basePrompt)
        self.currentStory = response
        return response
    }
    
    func processPlayerChoice(choice: String, player: Player, turnNumber: Int) async throws -> StoryResponse {
        let prompt = """
        GAME_CONTEXT
        - session_phase: ongoing_scene
        \(buildPlayerContext(player: player))
        - turn_number: \(turnNumber)
        \(buildPreviousStoryContext())
        - previous_choice: \(quoted(choice))
        \(player.hp <= 0 ? "- hard_rule: player_hp_is_zero => is_game_over_must_be_true" : "")
        
        TASK
        - Continue the story based on previous choice and current state.
        """
        
        let response = try await aiClient.generateStory(prompt: prompt)
        self.currentStory = response
        return response
    }
    
    /// Determines the outcome of a roll without generating the story yet.
    /// This allows the UI to show the result immediately.
    func resolveAction(rollResult: DiceResult) -> (hpChange: Int, dc: Int, outcome: Bool) {
        let dc = Int.random(in: 10...20)
        let isSuccess = rollResult.total >= dc
        let hpChange: Int
        hpChange = isSuccess ? 0 : -5
        return (hpChange, dc, isSuccess)
    }
    
    /// Generates the narrative for an action that has already been resolved.
    func generateResolvedStory(
        choice: String,
        player: Player,
        turnNumber: Int,
        rollResult: DiceResult,
        dc: Int,
        hpChange: Int,
        outcomeDescription: String
    ) async throws -> StoryResponse {
        // Generate compact structured context based on known outcome.
        let rollOutcome = hpChange < 0 ? "damage_\(abs(hpChange))" : "no_damage"
        
        let prompt = """
        GAME_CONTEXT
        - session_phase: post_roll_resolution
        \(buildPlayerContext(player: player))
        - turn_number: \(turnNumber)
        \(buildPreviousStoryContext())
        - previous_choice: \(quoted(choice))
        - resolved_roll:
          - d20: \(rollResult.roll)
          - modifier: \(rollResult.bonus)
          - total: \(rollResult.total)
          - dc: \(dc)
          - outcome: \(quoted(outcomeDescription))
          - consequence: \(rollOutcome)
        \(player.hp <= 0 ? "- hard_rule: player_hp_is_zero => is_game_over_must_be_true" : "")
        
        TASK
        - Continue the story based on resolved roll outcome and updated state.
        - Make roll consequences clear in scene description and choices.
        """
        
        let response = try await aiClient.generateStory(prompt: prompt)
        self.currentStory = response
        return response
    }
    
    // Kept for backward compatibility if needed, but implementation updated to use new methods
    func processPlayerChoiceWithRoll(
        choice: String,
        player: Player,
        turnNumber: Int,
        rollResult: DiceResult
    ) async throws -> (story: StoryResponse, hpChange: Int, dc: Int) {
        let (hpChange, dc, outcome) = resolveAction(rollResult: rollResult)
        let outcomeDescription = outcome ? "Success " : "Failure "
        let story = try await generateResolvedStory(
            choice: choice,
            player: player,
            turnNumber: turnNumber,
            rollResult: rollResult,
            dc: dc,
            hpChange: hpChange,
            outcomeDescription: outcomeDescription
        )
        return (story, hpChange, dc)
    }
    
    func generateRollContext(rollType: String, result: DiceResult) -> String {
        return "The player attempted a \(rollType.uppercased()) check and rolled a \(result.total) (d20: \(result.roll) + modifier: \(result.bonus))."
    }
    
    // Helper: Get ability modifier from player stats
    func getAbilityModifier(for ability: String, player: Player) -> Int {
        guard let abilityType = Ability(rawValue: ability.lowercased()) else {
            return 0
        }
        return player.abilityModifier(for: abilityType)
    }
    
    private func buildPlayerContext(player: Player) -> String {
        """
        - player:
          - name: \(quoted(player.name))
          - hp: \(player.hp)
          - max_hp: \(player.maxHP)
          - ability_scores:
            - strength: \(player.abilityScore(for: .strength))
            - dexterity: \(player.abilityScore(for: .dexterity))
            - constitution: \(player.abilityScore(for: .constitution))
            - intelligence: \(player.abilityScore(for: .intelligence))
            - wisdom: \(player.abilityScore(for: .wisdom))
            - charisma: \(player.abilityScore(for: .charisma))
          - inventory: \(player.inventory.isEmpty ? "[]" : "[" + player.inventory.map { quoted($0) }.joined(separator: ", ") + "]")
        """
    }
    
    private func buildPreviousStoryContext() -> String {
        guard let story = currentStory else {
            return "- previous_scene: none"
        }
        
        let sceneExcerpt = compact(story.sceneDescription, maxCharacters: 220)
        let priorChoices = story.choices.prefix(3).map { quoted($0) }.joined(separator: ", ")
        let rollRequirement = story.requiresRoll ?? "none"
        
        return """
        - previous_scene:
          - scene_excerpt: \(quoted(sceneExcerpt))
          - prior_choices: [\(priorChoices)]
          - required_roll: \(quoted(rollRequirement))
          - is_combat: \(story.isCombat ?? false)
          - is_game_over: \(story.isGameOver ?? false)
        """
    }
    
    private func compact(_ text: String, maxCharacters: Int) -> String {
        if text.count <= maxCharacters { return text }
        return String(text.prefix(maxCharacters)) + "..."
    }
    
    private func quoted(_ text: String) -> String {
        "\"\(text.replacingOccurrences(of: "\"", with: "\\\""))\""
    }
}
