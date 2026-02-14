import Foundation

struct StoryMemory: Codable {
    var currentQuest: String
    var majorEvents: [String]
    var unresolvedConflicts: [String]
    
    var summary: String {
        """
        Current Quest: \(currentQuest)
        Major Events: \(majorEvents.joined(separator: ", "))
        Unresolved Conflicts: \(unresolvedConflicts.joined(separator: ", "))
        """
    }
}

class Summarizer {
    // This will eventually call the AI to generate a summary
    func generateSummary(from history: [HistoryEntry]) -> StoryMemory {
        // Mocking summary logic for now - AI integration will happen in NarrativeOrchestrator
        return StoryMemory(
            currentQuest: "Unknown",
            majorEvents: history.map { $0.playerChoice },
            unresolvedConflicts: []
        )
    }
}
