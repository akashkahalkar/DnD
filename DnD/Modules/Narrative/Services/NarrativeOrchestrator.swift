import Foundation

class NarrativeOrchestrator {
    private let aiClient: AIClientProtocol
    private(set) var currentStory: StoryResponse?
    
    init(aiClient: AIClientProtocol = LLMClient()) {
        self.aiClient = aiClient
    }
    
    func startNewGame(player: Player) async throws -> StoryResponse {
        let basePrompt = """
        You are a Dungeon Master for a mythical RPG. 
        The player is \(player.name) with \(player.hp) HP.
        Start a new adventure in a dark, atmospheric setting.
        Output MUST be in JSON format matching the schema provided.
        """
        
        let response = try await aiClient.generateStory(prompt: basePrompt)
        self.currentStory = response
        return response
    }
    
    func processPlayerChoice(choice: String, player: Player) async throws -> StoryResponse {
        let prompt = """
        The player chose: "\(choice)".
        Current Player HP: \(player.hp).
        Continue the story based on this choice.
        Output MUST be in JSON format.
        """
        
        let response = try await aiClient.generateStory(prompt: prompt)
        self.currentStory = response
        return response
    }
    
    func generateRollContext(rollType: String, result: DiceResult) -> String {
        return "The player attempted a \(rollType) check and rolled a \(result.total) (Roll: \(result.roll) + Bonus: \(result.bonus))."
    }
}
