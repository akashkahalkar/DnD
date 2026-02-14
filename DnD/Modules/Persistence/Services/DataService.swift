import Foundation
import SwiftData

@MainActor
class DataService {
    static let shared = DataService()
    
    private let container: ModelContainer
    private let context: ModelContext
    
    private init() {
        do {
            container = try ModelContainer(for: GameData.self, StoryEntry.self)
            context = container.mainContext
        } catch {
            fatalError("Failed to initialize SwiftData container: \(error)")
        }
    }
    
    @discardableResult
    func saveGame(player: Player) -> GameData {
        let newRecord = GameData(player: player)
        context.insert(newRecord)
        try? context.save()
        return newRecord
    }
    
    func fetchLatestGame() -> GameData? {
        let descriptor = FetchDescriptor<GameData>(sortBy: [SortDescriptor(\.creationDate, order: .reverse)])
        return try? context.fetch(descriptor).first
    }
    
    func appendStory(to gameData: GameData, scene: String, choice: String?) {
        let entry = StoryEntry(sceneDescription: scene, playerChoice: choice)
        gameData.storyHistory.append(entry)
        try? context.save()
    }
    
    func updateGame(_ gameData: GameData, player: Player) {
        gameData.updatePlayerState(from: player)
        try? context.save()
    }
    
    func player(from gameData: GameData) -> Player {
        Player(
            name: gameData.playerName,
            hp: gameData.hp,
            maxHP: gameData.maxHP,
            abilityScores: [
                .strength: gameData.strength,
                .dexterity: gameData.dexterity,
                .constitution: gameData.constitution,
                .intelligence: gameData.intelligence,
                .wisdom: gameData.wisdom,
                .charisma: gameData.charisma
            ],
            unspentAbilityPoints: gameData.unspentAbilityPoints,
            inventory: gameData.inventory
        )
    }
}
