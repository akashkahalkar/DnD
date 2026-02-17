import Foundation
import SwiftData

@Model
final class CampaignProgressData {
    var campaignIndex: Int
    var seedTitle: String
    var isUnlocked: Bool
    var isCompleted: Bool

    @Relationship(deleteRule: .cascade)
    var quests: [QuestProgressData] = []

    init(campaignIndex: Int, seedTitle: String, isUnlocked: Bool, isCompleted: Bool) {
        self.campaignIndex = campaignIndex
        self.seedTitle = seedTitle
        self.isUnlocked = isUnlocked
        self.isCompleted = isCompleted
    }
}

@Model
final class QuestProgressData {
    var questIndex: Int
    var statusRaw: String
    var questTypeRaw: String
    var title: String?
    var summary: String?
    var outcomeRaw: String?
    var isBossQuest: Bool

    init(
        questIndex: Int,
        statusRaw: String,
        questTypeRaw: String,
        title: String? = nil,
        summary: String? = nil,
        outcomeRaw: String? = nil,
        isBossQuest: Bool
    ) {
        self.questIndex = questIndex
        self.statusRaw = statusRaw
        self.questTypeRaw = questTypeRaw
        self.title = title
        self.summary = summary
        self.outcomeRaw = outcomeRaw
        self.isBossQuest = isBossQuest
    }
}

@Model
final class CampaignRuntimeStateData {
    var activeCampaignIndex: Int
    var activeQuestIndex: Int
    var threatLevel: Int
    var bossPhase: Int
    var factionStateCompact: String
    var hooks: [String]
    var lastQuestSummary: String
    var previousQuestOutcomeRaw: String?

    init(
        activeCampaignIndex: Int,
        activeQuestIndex: Int,
        threatLevel: Int,
        bossPhase: Int,
        factionStateCompact: String,
        hooks: [String],
        lastQuestSummary: String,
        previousQuestOutcomeRaw: String?
    ) {
        self.activeCampaignIndex = activeCampaignIndex
        self.activeQuestIndex = activeQuestIndex
        self.threatLevel = threatLevel
        self.bossPhase = bossPhase
        self.factionStateCompact = factionStateCompact
        self.hooks = hooks
        self.lastQuestSummary = lastQuestSummary
        self.previousQuestOutcomeRaw = previousQuestOutcomeRaw
    }
}
