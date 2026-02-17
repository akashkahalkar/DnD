import Foundation

class NarrativeOrchestrator {
    private let aiClient: AIClientProtocol
    private(set) var currentStory: StoryResponse?
    
    @available(iOS 26.0, *)
    init(aiClient: AIClientProtocol = LLMClient()) {
        self.aiClient = aiClient
    }
    
    func startNewGame(player: Player, turnNumber: Int = 1, campaignContext: String = "") async throws -> StoryResponse {
        aiClient.resetSession()
        
        let prompt = """
        GAME_CONTEXT
        - phase: mission_start
        \(buildPlayerContext(player: player))
        \(campaignContext)
        - turn: \(turnNumber)/9
        
        TASK
        - Start a short dark-fantasy quest.
        - Introduce a clear objective or threat.
        - No combat yet.
        """
        
        var response = try await aiClient.generateStory(prompt: prompt)
        response.xpChange = calculateDeterministicXP(turn: turnNumber, outcome: response.questOutcome)
        self.currentStory = response
        return response
    }
    
    func processPlayerChoice(choice: String, player: Player, turnNumber: Int, campaignContext: String = "") async throws -> StoryResponse {
        let phase = determinePhase(turn: turnNumber)
        let prompt = """
        GAME_CONTEXT
        - phase: \(phase)
        \(buildPlayerContext(player: player))
        \(campaignContext)
        - turn: \(turnNumber)/9
        \(buildPreviousStoryContext())
        - choice: \(quoted(choice))
        
        TASK
        - Continue the story.
        \(phaseTaskInstructions(phase: phase))
        - Respect campaign context directives (quest_type/combat_allowed/boss_quest).
        """
        
        var response = try await aiClient.generateStory(prompt: prompt)
        response.xpChange = calculateDeterministicXP(turn: turnNumber, outcome: response.questOutcome)
        self.currentStory = response
        return response
    }
    
    /// Determines the outcome of a roll without generating the story yet.
    /// This allows the UI to show the result immediately.
    func resolveAction(
        rollResult: DiceResult,
        ability: String? = nil,
        player: Player? = nil
    ) -> (hpChange: Int, dc: Int, outcome: Bool) {
        var dc = Int.random(in: 10...20)
        if ability?.lowercased() == Ability.charisma.rawValue {
            dc = max(8, dc - 2)
        }
        if ability?.lowercased() == Ability.wisdom.rawValue, let player {
            dc = max(8, dc - max(0, player.abilityModifier(for: .wisdom)))
        }
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
        outcomeDescription: String,
        campaignContext: String = ""
    ) async throws -> StoryResponse {
        let phase = determinePhase(turn: turnNumber)
        let rollOutcome = hpChange < 0 ? "damage_\(abs(hpChange))" : "no_damage"
        
        let prompt = """
        GAME_CONTEXT
        - phase: \(phase) (post_roll)
        \(buildPlayerContext(player: player))
        \(campaignContext)
        - turn: \(turnNumber)/9
        \(buildPreviousStoryContext())
        - choice: \(quoted(choice))
        - roll: {d20: \(rollResult.roll), total: \(rollResult.total), dc: \(dc), outcome: \(quoted(outcomeDescription)), consequence: \(rollOutcome)}
        
        TASK
        - Continue story with roll results.
        \(phaseTaskInstructions(phase: phase))
        - Respect campaign context directives (quest_type/combat_allowed/boss_quest).
        """
        
        var response = try await aiClient.generateStory(prompt: prompt)
        response.xpChange = calculateDeterministicXP(turn: turnNumber, outcome: response.questOutcome)
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
            outcomeDescription: outcomeDescription,
            campaignContext: ""
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
        - player: {hp: \(player.hp)/\(player.maxHP), stats: STR\(player.abilityScore(for: .strength)) DEX\(player.abilityScore(for: .dexterity)) CON\(player.abilityScore(for: .constitution)) INT\(player.abilityScore(for: .intelligence)) WIS\(player.abilityScore(for: .wisdom)) CHA\(player.abilityScore(for: .charisma)), items: \(player.inventory.isEmpty ? "[]" : "[" + player.inventory.joined(separator: ", ") + "]")}
        """
    }
    
    private func determinePhase(turn: Int) -> String {
        if turn <= 7 { return "exploration" }
        if turn == 8 { return "final_encounter_buildup" }
        return "resolution"
    }
    
    private func phaseTaskInstructions(phase: String) -> String {
        switch phase {
        case "exploration":
            return "- Focus on atmosphere and buildup. No combat."
        case "final_encounter_buildup":
            return """
            - If combat_allowed=true, set is_combat=true and create confrontation pressure.
            - If combat_allowed=false, keep is_combat=false and resolve without battle.
            - If boss_quest=true, confrontation should involve boss pressure.
            - quest_outcome should remain in_progress.
            """
        case "resolution":
            return """
            - Final result. Set quest_outcome to 'success' or 'failure' based on story logic.
            """
        default:
            return ""
        }
    }
    
    private func calculateDeterministicXP(turn: Int, outcome: String?) -> Int {
        // Base turn XP
        var xp = 10
        
        // Bonus/Penalty at the end
        if turn >= 9 {
            if outcome == "success" {
                xp += 100
            } else if outcome == "failure" {
                xp -= 50
            }
        }
        
        return xp
    }
    
    private func buildPreviousStoryContext() -> String {
        guard let story = currentStory else {
            return "- prev_scene: none"
        }
        
        let sceneExcerpt = compact(story.sceneDescription, maxCharacters: 180)
        let priorChoices = story.choices.prefix(2).joined(separator: ", ")
        
        return """
        - prev_scene: {text: \(quoted(sceneExcerpt)), choices: [\(priorChoices)], roll: \(story.requiresRoll ?? "none"), is_combat: \(story.isCombat ?? false)}
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
