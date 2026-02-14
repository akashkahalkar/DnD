import Foundation

struct PromptBuilder {
    static let baseStyleAnchor = "Semi-realistic fantasy RPG portrait, painterly, soft dramatic lighting, neutral background, head and shoulders framing"
    
    static func buildCharacterPrompt(description: String) -> String {
        return "\(baseStyleAnchor), \(description)"
    }
    
    static func buildEnemyPrompt(enemyType: String, traits: [String]) -> String {
        let traitString = traits.joined(separator: ", ")
        return "\(baseStyleAnchor), \(enemyType), \(traitString)"
    }
}
