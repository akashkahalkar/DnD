import Foundation

enum Mood: String, Codable {
    case happy, fearful, angry, neutral, cautious
}

struct EmotionalState: Codable {
    var trust: Int // 0-100
    var fear: Int  // 0-100
    var loyalty: Int // 0-100
}

struct Companion: Codable {
    var name: String
    var mood: Mood
    var emotionalState: EmotionalState
    
    var shortDescription: String {
        "\(name) is feeling \(mood.rawValue)."
    }
}
