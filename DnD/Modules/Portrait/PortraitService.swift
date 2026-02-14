import SwiftUI

class PortraitService {
    private let generator: ImageGeneratorProtocol
    private let cache: PortraitCache
    
    init(generator: ImageGeneratorProtocol = ImageGenerator(), cache: PortraitCache = .shared) {
        self.generator = generator
        self.cache = cache
    }
    
    /// Fetches a portrait for the given description. Checks cache first.
    func fetchPortrait(description: String) async throws -> UIImage {
        let prompt = PromptBuilder.buildCharacterPrompt(description: description)
        
        // 1. Check Cache
        if let cachedImage = cache.getImage(for: prompt) {
            return cachedImage
        }
        
        // 2. Generate if not cached
        let generatedImage = try await generator.generateImage(prompt: prompt)
        
        // 3. Save to Cache
        cache.saveImage(generatedImage, for: prompt)
        
        return generatedImage
    }
    
    /// Fetches an enemy portrait based on type and traits.
    func fetchEnemyPortrait(type: String, traits: [String]) async throws -> UIImage {
        let prompt = PromptBuilder.buildEnemyPrompt(enemyType: type, traits: traits)
        
        if let cachedImage = cache.getImage(for: prompt) {
            return cachedImage
        }
        
        let generatedImage = try await generator.generateImage(prompt: prompt)
        cache.saveImage(generatedImage, for: prompt)
        
        return generatedImage
    }
}
