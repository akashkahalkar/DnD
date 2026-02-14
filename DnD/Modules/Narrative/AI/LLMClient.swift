import Foundation

/// Interface for Apple Foundation Models (Mock for now)
protocol AIClientProtocol {
    func generateStory(prompt: String) async throws -> StoryResponse
}

class LLMClient: AIClientProtocol {
    func generateStory(prompt: String) async throws -> StoryResponse {
        // In a real implementation, this would call Apple's on-device model APIs.
        // Returning a mock response for development purposes.
        
        let mockJSON = """
        {
          "scene_description": "The air in the cavern is thick with the scent of ozone and ancient stone. Before you, a massive dragon scales glisten in the dim light.",
          "npc_dialogue": [
            {
              "speaker": "Kael",
              "line": "Steady now. One wrong move and we're charbroiled."
            }
          ],
          "choices": [
            "Attempt to reason with it",
            "Prepare a defensive spell",
            "Look for an exit"
          ],
          "requires_roll": "charisma"
        }
        """
        
        let data = mockJSON.data(using: .utf8)!
        return try JSONDecoder().decode(StoryResponse.self, from: data)
    }
}
