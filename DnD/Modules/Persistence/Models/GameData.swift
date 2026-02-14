import Foundation
import SwiftData

@Model
final class GameData {
    var playerID: UUID
    var playerName: String
    var hp: Int
    var maxHP: Int
    var strength: Int
    var charisma: Int
    var inventory: [String]
    var creationDate: Date
    
    @Relationship(deleteRule: .cascade)
    var storyHistory: [StoryEntry] = []
    
    init(player: Player) {
        self.playerID = UUID()
        self.playerName = player.name
        self.hp = player.hp
        self.maxHP = player.maxHP
        self.strength = player.strength
        self.charisma = player.charisma
        self.inventory = player.inventory
        self.creationDate = Date()
    }
}

@Model
final class StoryEntry {
    var timestamp: Date
    var sceneDescription: String
    var playerChoice: String?
    
    init(sceneDescription: String, playerChoice: String? = nil) {
        self.timestamp = Date()
        self.sceneDescription = sceneDescription
        self.playerChoice = playerChoice
    }
}
