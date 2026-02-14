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
        You are a Dungeon Master for a mythical RPG. 
        The player is \(player.name) with \(player.hp) HP.
        Current scene turn number: \(turnNumber).
        This is the opening scene of the adventure.
        Start a new adventure in a dark, atmospheric mythical setting.
        Output MUST be in JSON format matching the schema provided.
        """
        
        let response = try await aiClient.generateStory(prompt: basePrompt)
        self.currentStory = response
        return response
    }
    
    func processPlayerChoice(choice: String, player: Player, turnNumber: Int) async throws -> StoryResponse {
        let prompt = """
        The player chose: "\(choice)".
        Current scene turn number: \(turnNumber).
        Current Player HP: \(player.hp).
        Continue the story based on this choice.
        Output MUST be in JSON format.
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
        let outcomeDescription: String
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
        // Generate Prompt context based on known outcome
        let damageContext = hpChange < 0 ? "The player took \(abs(hpChange)) damage." : ""
        let rollContext = "Player rolled \(rollResult.total) (d20: \(rollResult.roll) + \(rollResult.bonus)) against DC \(dc)."
        
        let prompt = """
        The player chose: "\(choice)".
        Current scene turn number: \(turnNumber).
        \(rollContext)
        \(outcomeDescription)
        \(damageContext)
        
        Current Player HP: \(player.hp).
        Continue the story based on this choice and the roll outcome.
        Make the consequences of the roll clear in the narrative.
        Output MUST be in JSON format.
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
}
