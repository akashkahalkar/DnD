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
    
    func saveGame(player: Player) {
        let newRecord = GameData(player: player)
        context.insert(newRecord)
        try? context.save()
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
}
