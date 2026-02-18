import Foundation

class NarrativeOrchestrator {
    private let aiClient: AIClientProtocol
    private(set) var currentStory: StoryResponse?
    private var activeQuestGoal: String?
    
    @available(iOS 26.0, *)
    init(aiClient: AIClientProtocol = LLMClient.shared) {
        self.aiClient = aiClient
    }
    
    func startNewGame(player: Player, turnNumber: Int = 1, campaignContext _: String = "") async throws -> StoryResponse {
        aiClient.resetSession()
        activeQuestGoal = nil
        
        let level = levelForTurn(turnNumber)
        let prompt = """
        Create a dark-fantasy quest.
        Keep language short and plain English.
        This is level \(level) of 5.
        Player HP: \(player.hp)/\(player.maxHP).
        Define one clear end goal in one sentence as quest_goal.
        Return exactly 2 choices.
        Exactly one choice must be correct. Set correct_choice_index to 1 or 2.
        Set quest_outcome to in_progress.
        No combat in this opening scene.
        """
        var response = try await aiClient.generateStory(prompt: prompt)
        if let goal = normalizedGoal(from: response.questGoal) {
            activeQuestGoal = goal
        }
        response.xpChange = calculateDeterministicXP(turn: turnNumber, outcome: response.questOutcome)
        self.currentStory = response
        return response
    }
    
    func processPlayerChoice(choice: String, player: Player, turnNumber: Int, campaignContext _: String = "") async throws -> StoryResponse {
        let level = levelForTurn(turnNumber)
        let goal = activeQuestGoal ?? normalizedGoal(from: currentStory?.questGoal) ?? "Complete the quest objective."
        let correctness = selectedChoiceCorrectness(for: choice)
        let outcomeRule = level < 5
            ? "Set quest_outcome to in_progress."
            : "Set quest_outcome to success or failure based on earlier choices. In scene_description, clearly say what objective was achieved or failed."
        let prompt = """
        Continue this quest in plain English.
        Current level: \(level) of 5.
        Player HP: \(player.hp)/\(player.maxHP).
        End goal: \(quoted(goal))
        Selected choice: \(quoted(choice))
        Choice result: \(correctness)
        If choice result is correct, progress toward the end goal.
        If choice result is wrong, add setback and failure risk.
        Return exactly 2 choices.
        Exactly one choice must be correct. Set correct_choice_index to 1 or 2.
        \(outcomeRule)
        """
        var response = try await aiClient.generateStory(prompt: prompt)
        if let goal = normalizedGoal(from: response.questGoal) {
            activeQuestGoal = goal
        }
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
        campaignContext _: String = ""
    ) async throws -> StoryResponse {
        let level = levelForTurn(turnNumber)
        let goal = activeQuestGoal ?? normalizedGoal(from: currentStory?.questGoal) ?? "Complete the quest objective."
        let rollOutcome = hpChange < 0 ? "damage_\(abs(hpChange))" : "no_damage"
        let sceneExcerpt = compact(currentStory?.sceneDescription ?? "", maxCharacters: 220)
        let correctness = hpChange < 0 ? "wrong" : "correct"
        let outcomeRule = level < 5
            ? "Set quest_outcome to in_progress."
            : "Set quest_outcome to success or failure based on earlier choices. In scene_description, clearly say what objective was achieved or failed."
        
        let prompt = """
        Continue this quest.
        Current level: \(level) of 5.
        Player HP: \(player.hp)/\(player.maxHP).
        End goal: \(quoted(goal))
        Current scene: \(quoted(sceneExcerpt.isEmpty ? "Unknown scene context." : sceneExcerpt))
        Selected choice: \(quoted(choice))
        Choice result: \(correctness)
        If choice result is correct, progress toward the end goal.
        If choice result is wrong, add setback and failure risk.
        Return exactly 3 choices.
        Exactly one choice must be correct. Set correct_choice_index to 1 or 2 or 3.
        \(outcomeRule)
        """
        var response = try await aiClient.generateStory(prompt: prompt)
        if let goal = normalizedGoal(from: response.questGoal) {
            activeQuestGoal = goal
        }
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

    private func levelForTurn(_ turn: Int) -> Int {
        min(5, max(1, turn))
    }

    private func selectedChoiceCorrectness(for selectedChoice: String) -> String {
        guard let story = currentStory,
              let index = story.choices.firstIndex(of: selectedChoice),
              let correctIndex = story.correctChoiceIndex else {
            return "unknown"
        }
        return (index + 1) == correctIndex ? "correct" : "wrong"
    }

    private func normalizedGoal(from rawGoal: String?) -> String? {
        guard let rawGoal else { return nil }
        let trimmed = rawGoal.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
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
