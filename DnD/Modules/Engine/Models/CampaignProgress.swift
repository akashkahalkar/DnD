import Foundation

enum QuestStatus: String, Codable, CaseIterable {
    case locked
    case available
    case inProgress
    case success
    case failed
}

enum QuestType: String, Codable, CaseIterable {
    case investigation
    case social
    case combat
    case survival
    case infiltration
    case moralChoice
    case travelHazard
}

struct QuestProgress: Codable, Hashable {
    var questIndex: Int
    var status: QuestStatus
    var questType: QuestType
    var title: String?
    var summary: String?
    var outcome: QuestOutcome?
    var isBossQuest: Bool
}

struct CampaignProgress: Codable, Hashable {
    var campaignIndex: Int
    var seedTitle: String
    var isUnlocked: Bool
    var isCompleted: Bool
    var quests: [QuestProgress]
}

struct CampaignRuntimeState: Codable, Hashable {
    var activeCampaignIndex: Int
    var activeQuestIndex: Int
    var threatLevel: Int
    var bossPhase: Int
    var factionStateCompact: String
    var hooks: [String]
    var lastQuestSummary: String
    var previousQuestOutcome: QuestOutcome?
}
