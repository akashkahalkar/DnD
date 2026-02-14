import Combine
import SwiftUI

@MainActor
class PortraitVerifier: ObservableObject {
    @Published var status: String = "Ready"
    @Published var lastGeneratedImage: UIImage?
    @Published var lastPrompt: String = ""
    @Published var isProcessing: Bool = false
    
    private let service: PortraitService
    private let mockGenerator: MockImageGenerator
    
    init() {
        let mock = MockImageGenerator()
        self.mockGenerator = mock
        self.service = PortraitService(generator: mock)
    }
    
    func verifyGeneration(description: String) async {
        isProcessing = true
        status = "Generating..."
        lastPrompt = PromptBuilder.buildCharacterPrompt(description: description)
        
        do {
            let image = try await service.fetchPortrait(description: description)
            lastGeneratedImage = image
            status = "Success! (Cached: \(serviceIsUsingCache(for: description)))"
        } catch {
            status = "Error: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    private func serviceIsUsingCache(for description: String) -> String {
        let prompt = PromptBuilder.buildCharacterPrompt(description: description)
        return PortraitCache.shared.getImage(for: prompt) != nil ? "Yes" : "No"
    }
}

