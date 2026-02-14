import Foundation
import SwiftData

@Model
final class GameData {
    var playerID: UUID
    var playerName: String
    var hp: Int
    var maxHP: Int
    var strength: Int
    var dexterity: Int
    var constitution: Int
    var intelligence: Int
    var wisdom: Int
    var charisma: Int
    var unspentAbilityPoints: Int
    var inventory: [String]
    var creationDate: Date
    
    @Relationship(deleteRule: .cascade)
    var storyHistory: [StoryEntry] = []
    
    init(player: Player) {
        self.playerID = UUID()
        self.playerName = player.name
        self.hp = player.hp
        self.maxHP = player.maxHP
        self.strength = player.abilityScore(for: .strength)
        self.dexterity = player.abilityScore(for: .dexterity)
        self.constitution = player.abilityScore(for: .constitution)
        self.intelligence = player.abilityScore(for: .intelligence)
        self.wisdom = player.abilityScore(for: .wisdom)
        self.charisma = player.abilityScore(for: .charisma)
        self.unspentAbilityPoints = player.unspentAbilityPoints
        self.inventory = player.inventory
        self.creationDate = Date()
    }
    
    func updatePlayerState(from player: Player) {
        playerName = player.name
        hp = player.hp
        maxHP = player.maxHP
        strength = player.abilityScore(for: .strength)
        dexterity = player.abilityScore(for: .dexterity)
        constitution = player.abilityScore(for: .constitution)
        intelligence = player.abilityScore(for: .intelligence)
        wisdom = player.abilityScore(for: .wisdom)
        charisma = player.abilityScore(for: .charisma)
        unspentAbilityPoints = player.unspentAbilityPoints
        inventory = player.inventory
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
