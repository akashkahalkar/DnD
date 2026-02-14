import Foundation

struct HistoryEntry: Codable {
    let turn: Int
    let playerChoice: String
    let storySegment: String
}

class HistoryManager {
    private let maxHistoryTurns = 10
    private var entries: [HistoryEntry] = []
    
    func append(choice: String, story: String) {
        let entry = HistoryEntry(turn: entries.count + 1, playerChoice: choice, storySegment: story)
        entries.append(entry)
        
        // Keep only the most recent turns for short-term context
        if entries.count > maxHistoryTurns {
            entries.removeFirst()
        }
    }
    
    func getContextString() -> String {
        entries.map { entry in
            "Turn \(entry.turn):\nPlayer: \(entry.playerChoice)\nDM: \(entry.storySegment)"
        }.joined(separator: "\n\n")
    }
    
    func getAllEntries() -> [HistoryEntry] {
        entries
    }
    
    func clear() {
        entries.removeAll()
    }
}
