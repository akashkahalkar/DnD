import Foundation

@available(iOS 26.0, *)
@MainActor
final class CampaignService {
    static let shared = CampaignService()

    private let dataService: DataService
    private let llmClient: LLMClient

    init(dataService: DataService = .shared, llmClient: LLMClient = LLMClient()) {
        self.dataService = dataService
        self.llmClient = llmClient
    }

    func ensureCampaignData(for gameData: GameData) async {
        if !dataService.loadCampaignProgress(from: gameData).isEmpty {
            return
        }

        let seedTitles = await llmClient.generateCampaignSeeds(count: 6)
        let campaigns = buildDefaultCampaigns(seedTitles: seedTitles)
        dataService.saveCampaignProgress(campaigns, to: gameData)
        dataService.saveCampaignRuntimeState(defaultRuntimeState(), to: gameData)
    }

    func campaigns(for gameData: GameData) -> [CampaignProgress] {
        dataService.loadCampaignProgress(from: gameData)
    }

    func runtimeState(for gameData: GameData) -> CampaignRuntimeState {
        dataService.loadCampaignRuntimeState(from: gameData) ?? defaultRuntimeState()
    }

    func activeQuest(for gameData: GameData) -> QuestProgress? {
        let runtime = runtimeState(for: gameData)
        return dataService.loadCampaignProgress(from: gameData)
            .first(where: { $0.campaignIndex == runtime.activeCampaignIndex })?
            .quests
            .first(where: { $0.questIndex == runtime.activeQuestIndex })
    }

    func startActiveQuestIfNeeded(for gameData: GameData) {
        var campaigns = dataService.loadCampaignProgress(from: gameData)
        let runtime = runtimeState(for: gameData)

        guard let campaignIndex = campaigns.firstIndex(where: { $0.campaignIndex == runtime.activeCampaignIndex }) else {
            return
        }

        var campaign = campaigns[campaignIndex]
        guard let questIndex = campaign.quests.firstIndex(where: { $0.questIndex == runtime.activeQuestIndex }) else {
            return
        }

        if campaign.quests[questIndex].status == .available {
            campaign.quests[questIndex].status = .inProgress
            campaigns[campaignIndex] = campaign
            dataService.saveCampaignProgress(campaigns, to: gameData)
            dataService.saveCampaignRuntimeState(runtime, to: gameData)
        }
    }

    func completeActiveQuest(
        for gameData: GameData,
        outcome: QuestOutcome,
        title: String,
        summary: String,
        wisdomModifier: Int
    ) {
        var campaigns = dataService.loadCampaignProgress(from: gameData)
        var runtime = runtimeState(for: gameData)

        guard let campaignIndex = campaigns.firstIndex(where: { $0.campaignIndex == runtime.activeCampaignIndex }) else {
            return
        }

        var campaign = campaigns[campaignIndex]
        guard let questIndex = campaign.quests.firstIndex(where: { $0.questIndex == runtime.activeQuestIndex }) else {
            return
        }

        campaign.quests[questIndex].status = outcome == .success ? .success : .failed
        campaign.quests[questIndex].title = title
        campaign.quests[questIndex].summary = String(summary.prefix(120))
        campaign.quests[questIndex].outcome = outcome

        runtime.previousQuestOutcome = outcome
        runtime.lastQuestSummary = String(summary.prefix(120))
        let threatIncreaseOnFailure = max(0, 1 - max(0, wisdomModifier))
        let threatDelta = outcome == .success ? -1 : threatIncreaseOnFailure
        runtime.threatLevel = max(0, min(10, runtime.threatLevel + threatDelta))
        runtime.bossPhase = bossPhase(for: runtime.activeQuestIndex)
        runtime.hooks = nextHooks(
            current: runtime.hooks,
            questIndex: runtime.activeQuestIndex,
            outcome: outcome
        )

        let nextQuest = runtime.activeQuestIndex + 1
        if nextQuest <= 9 {
            if let nextQuestIndex = campaign.quests.firstIndex(where: { $0.questIndex == nextQuest }) {
                campaign.quests[nextQuestIndex].status = .available
                runtime.activeQuestIndex = nextQuest
            }
        } else {
            campaign.isCompleted = true
            let nextCampaign = runtime.activeCampaignIndex + 1
            if nextCampaign <= campaigns.count {
                if let nextCampaignIndex = campaigns.firstIndex(where: { $0.campaignIndex == nextCampaign }) {
                    campaigns[nextCampaignIndex].isUnlocked = true
                    if let firstQuestIndex = campaigns[nextCampaignIndex].quests.firstIndex(where: { $0.questIndex == 1 }) {
                        if campaigns[nextCampaignIndex].quests[firstQuestIndex].status == .locked {
                            campaigns[nextCampaignIndex].quests[firstQuestIndex].status = .available
                        }
                    }
                }
                runtime.activeCampaignIndex = nextCampaign
                runtime.activeQuestIndex = 1
            }
        }

        campaigns[campaignIndex] = campaign
        dataService.saveCampaignProgress(campaigns, to: gameData)
        dataService.saveCampaignRuntimeState(runtime, to: gameData)
    }

    private func buildDefaultCampaigns(seedTitles: [String]) -> [CampaignProgress] {
        let seeds = (seedTitles + fallbackSeeds()).prefix(6)

        return Array(seeds.enumerated()).map { offset, seed in
            let campaignIndex = offset + 1
            let quests = (1...9).map { index in
                QuestProgress(
                    questIndex: index,
                    status: campaignIndex == 1 && index == 1 ? .available : .locked,
                    questType: defaultQuestType(for: index),
                    title: nil,
                    summary: nil,
                    outcome: nil,
                    isBossQuest: [3, 6, 9].contains(index)
                )
            }

            return CampaignProgress(
                campaignIndex: campaignIndex,
                seedTitle: seed,
                isUnlocked: campaignIndex == 1,
                isCompleted: false,
                quests: quests
            )
        }
    }

    private func defaultRuntimeState() -> CampaignRuntimeState {
        CampaignRuntimeState(
            activeCampaignIndex: 1,
            activeQuestIndex: 1,
            threatLevel: 2,
            bossPhase: 0,
            factionStateCompact: "rebels:0,cult:0",
            hooks: [],
            lastQuestSummary: "",
            previousQuestOutcome: nil
        )
    }

    private func defaultQuestType(for questIndex: Int) -> QuestType {
        switch questIndex {
        case 1:
            return .investigation
        case 2:
            return .social
        case 3:
            return .combat
        case 4:
            return .infiltration
        case 5:
            return .survival
        case 6:
            return .combat
        case 7:
            return .travelHazard
        case 8:
            return .moralChoice
        default:
            return .combat
        }
    }

    private func bossPhase(for questIndex: Int) -> Int {
        if questIndex >= 9 { return 3 }
        if questIndex >= 6 { return 2 }
        if questIndex >= 3 { return 1 }
        return 0
    }

    private func fallbackSeeds() -> [String] {
        [
            "Crimson Eclipse",
            "Thornbound Oath",
            "Ashen Crown",
            "Veil of Cinders",
            "Frostbound Sigil",
            "Hollow Star"
        ]
    }

    private func nextHooks(current: [String], questIndex: Int, outcome: QuestOutcome) -> [String] {
        var hooks = current
        let newHook = outcome == .success
            ? "quest\(questIndex)_opened_path"
            : "quest\(questIndex)_setback"
        hooks.append(newHook)
        return Array(hooks.suffix(2))
    }
}
