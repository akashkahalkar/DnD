import Foundation
import SwiftData

@MainActor
class DataService {
    static let shared = DataService()
    
    private let container: ModelContainer
    private let context: ModelContext
    
    private init() {
        do {
            container = try ModelContainer(
                for: GameData.self,
                StoryEntry.self,
                RunStateData.self,
                CombatStateData.self,
                ProgressionStateData.self,
                CampaignProgressData.self,
                QuestProgressData.self,
                CampaignRuntimeStateData.self
            )
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

    func saveRunState(
        _ runState: RunState,
        combatState: CombatState? = nil,
        progressionState: ProgressionState? = nil,
        to gameData: GameData
    ) {
        if let existing = gameData.runState {
            existing.phaseRaw = runState.phase.rawValue
            existing.turnNumber = runState.turnNumber
            existing.questOutcomeRaw = runState.questOutcome?.rawValue
            updateEnemyFields(in: existing, enemy: runState.activeEnemy)
        } else {
            let newState = RunStateData(
                phaseRaw: runState.phase.rawValue,
                turnNumber: runState.turnNumber,
                questOutcomeRaw: runState.questOutcome?.rawValue
            )
            updateEnemyFields(in: newState, enemy: runState.activeEnemy)
            gameData.runState = newState
        }

        if let combatState {
            saveCombatState(combatState, to: gameData)
        }

        if let progressionState {
            saveProgressionState(progressionState, to: gameData)
        }

        try? context.save()
    }

    func saveCombatState(_ combatState: CombatState, to gameData: GameData) {
        if let existing = gameData.combatState {
            existing.enemyName = combatState.enemy.name
            existing.enemyType = combatState.enemy.type
            existing.enemyHP = combatState.enemy.hp
            existing.enemyMaxHP = combatState.enemy.maxHP
            existing.enemyAttackPower = combatState.enemy.attackPower
            existing.playerTurn = combatState.playerTurn
            existing.lastActionResult = combatState.lastActionResult
            existing.roundNumber = combatState.roundNumber
        } else {
            let newState = CombatStateData(
                enemyName: combatState.enemy.name,
                enemyType: combatState.enemy.type,
                enemyHP: combatState.enemy.hp,
                enemyMaxHP: combatState.enemy.maxHP,
                enemyAttackPower: combatState.enemy.attackPower,
                playerTurn: combatState.playerTurn,
                lastActionResult: combatState.lastActionResult,
                roundNumber: combatState.roundNumber
            )
            gameData.combatState = newState
        }
        try? context.save()
    }

    func saveProgressionState(_ progressionState: ProgressionState, to gameData: GameData) {
        if let existing = gameData.progressionState {
            existing.xp = progressionState.xp
            existing.level = progressionState.level
            existing.unspentPoints = progressionState.unspentPoints
            existing.recentRewards = progressionState.recentRewards
        } else {
            let newState = ProgressionStateData(
                xp: progressionState.xp,
                level: progressionState.level,
                unspentPoints: progressionState.unspentPoints,
                recentRewards: progressionState.recentRewards
            )
            gameData.progressionState = newState
        }
        try? context.save()
    }

    func loadRunState(from gameData: GameData) -> RunState? {
        guard let data = gameData.runState else { return nil }
        return RunState(
            phase: RunPhase(rawValue: data.phaseRaw) ?? .narrative,
            turnNumber: data.turnNumber,
            questOutcome: data.questOutcomeRaw.flatMap { QuestOutcome(rawValue: $0) },
            activeEnemy: enemyFromRunState(data)
        )
    }

    func loadCombatState(from gameData: GameData) -> CombatState? {
        guard let data = gameData.combatState else { return nil }
        let enemy = Enemy(
            name: data.enemyName,
            hp: data.enemyHP,
            maxHP: data.enemyMaxHP,
            attackPower: data.enemyAttackPower,
            type: data.enemyType
        )
        return CombatState(
            enemy: enemy,
            playerTurn: data.playerTurn,
            lastActionResult: data.lastActionResult,
            roundNumber: data.roundNumber
        )
    }

    func loadProgressionState(from gameData: GameData) -> ProgressionState? {
        guard let data = gameData.progressionState else { return nil }
        return ProgressionState(
            xp: data.xp,
            level: data.level,
            unspentPoints: data.unspentPoints,
            recentRewards: data.recentRewards
        )
    }

    func completeRun(_ gameData: GameData, phase: RunPhase, questOutcome: QuestOutcome? = nil) {
        let updated = RunState(
            phase: phase,
            turnNumber: gameData.runState?.turnNumber ?? 0,
            questOutcome: questOutcome,
            activeEnemy: nil
        )
        saveRunState(updated, to: gameData)
    }
    
    func player(from gameData: GameData) -> Player {
        Player(
            name: gameData.playerName,
            hp: gameData.hp,
            maxHP: gameData.maxHP,
            archetype: gameData.archetype ?? Player.defaultArchetype,
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

    func clearAllSaves() {
        let descriptor = FetchDescriptor<GameData>()
        if let games = try? context.fetch(descriptor) {
            for game in games {
                context.delete(game)
            }
            try? context.save()
        }
    }

    func loadCampaignProgress(from gameData: GameData) -> [CampaignProgress] {
        gameData.campaignProgress
            .sorted(by: { $0.campaignIndex < $1.campaignIndex })
            .map { campaign in
                CampaignProgress(
                    campaignIndex: campaign.campaignIndex,
                    seedTitle: campaign.seedTitle,
                    isUnlocked: campaign.isUnlocked,
                    isCompleted: campaign.isCompleted,
                    quests: campaign.quests
                        .sorted(by: { $0.questIndex < $1.questIndex })
                        .map { quest in
                            QuestProgress(
                                questIndex: quest.questIndex,
                                status: QuestStatus(rawValue: quest.statusRaw) ?? .locked,
                                questType: QuestType(rawValue: quest.questTypeRaw) ?? .investigation,
                                title: quest.title,
                                summary: quest.summary,
                                outcome: quest.outcomeRaw.flatMap { QuestOutcome(rawValue: $0) },
                                isBossQuest: quest.isBossQuest
                            )
                        }
                )
            }
    }

    func saveCampaignProgress(_ campaigns: [CampaignProgress], to gameData: GameData) {
        var byIndex = Dictionary(uniqueKeysWithValues: gameData.campaignProgress.map { ($0.campaignIndex, $0) })

        for campaign in campaigns {
            let target = byIndex[campaign.campaignIndex] ?? {
                let created = CampaignProgressData(
                    campaignIndex: campaign.campaignIndex,
                    seedTitle: campaign.seedTitle,
                    isUnlocked: campaign.isUnlocked,
                    isCompleted: campaign.isCompleted
                )
                gameData.campaignProgress.append(created)
                byIndex[campaign.campaignIndex] = created
                return created
            }()

            target.seedTitle = campaign.seedTitle
            target.isUnlocked = campaign.isUnlocked
            target.isCompleted = campaign.isCompleted

            var questByIndex = Dictionary(uniqueKeysWithValues: target.quests.map { ($0.questIndex, $0) })
            for quest in campaign.quests {
                let qTarget = questByIndex[quest.questIndex] ?? {
                    let created = QuestProgressData(
                        questIndex: quest.questIndex,
                        statusRaw: quest.status.rawValue,
                        questTypeRaw: quest.questType.rawValue,
                        title: quest.title,
                        summary: quest.summary,
                        outcomeRaw: quest.outcome?.rawValue,
                        isBossQuest: quest.isBossQuest
                    )
                    target.quests.append(created)
                    questByIndex[quest.questIndex] = created
                    return created
                }()

                qTarget.statusRaw = quest.status.rawValue
                qTarget.questTypeRaw = quest.questType.rawValue
                qTarget.title = quest.title
                qTarget.summary = quest.summary
                qTarget.outcomeRaw = quest.outcome?.rawValue
                qTarget.isBossQuest = quest.isBossQuest
            }
        }

        try? context.save()
    }

    func loadCampaignRuntimeState(from gameData: GameData) -> CampaignRuntimeState? {
        guard let runtime = gameData.campaignRuntimeState else { return nil }
        return CampaignRuntimeState(
            activeCampaignIndex: runtime.activeCampaignIndex,
            activeQuestIndex: runtime.activeQuestIndex,
            threatLevel: runtime.threatLevel,
            bossPhase: runtime.bossPhase,
            factionStateCompact: runtime.factionStateCompact,
            hooks: runtime.hooks,
            lastQuestSummary: runtime.lastQuestSummary,
            previousQuestOutcome: runtime.previousQuestOutcomeRaw.flatMap { QuestOutcome(rawValue: $0) }
        )
    }

    func saveCampaignRuntimeState(_ runtimeState: CampaignRuntimeState, to gameData: GameData) {
        if let existing = gameData.campaignRuntimeState {
            existing.activeCampaignIndex = runtimeState.activeCampaignIndex
            existing.activeQuestIndex = runtimeState.activeQuestIndex
            existing.threatLevel = runtimeState.threatLevel
            existing.bossPhase = runtimeState.bossPhase
            existing.factionStateCompact = runtimeState.factionStateCompact
            existing.hooks = runtimeState.hooks
            existing.lastQuestSummary = runtimeState.lastQuestSummary
            existing.previousQuestOutcomeRaw = runtimeState.previousQuestOutcome?.rawValue
        } else {
            gameData.campaignRuntimeState = CampaignRuntimeStateData(
                activeCampaignIndex: runtimeState.activeCampaignIndex,
                activeQuestIndex: runtimeState.activeQuestIndex,
                threatLevel: runtimeState.threatLevel,
                bossPhase: runtimeState.bossPhase,
                factionStateCompact: runtimeState.factionStateCompact,
                hooks: runtimeState.hooks,
                lastQuestSummary: runtimeState.lastQuestSummary,
                previousQuestOutcomeRaw: runtimeState.previousQuestOutcome?.rawValue
            )
        }
        try? context.save()
    }

    private func updateEnemyFields(in runStateData: RunStateData, enemy: Enemy?) {
        runStateData.activeEnemyName = enemy?.name
        runStateData.activeEnemyType = enemy?.type
        runStateData.activeEnemyHP = enemy?.hp
        runStateData.activeEnemyMaxHP = enemy?.maxHP
        runStateData.activeEnemyAttackPower = enemy?.attackPower
    }

    private func enemyFromRunState(_ runStateData: RunStateData) -> Enemy? {
        guard
            let name = runStateData.activeEnemyName,
            let type = runStateData.activeEnemyType,
            let hp = runStateData.activeEnemyHP,
            let maxHP = runStateData.activeEnemyMaxHP,
            let attackPower = runStateData.activeEnemyAttackPower
        else { return nil }

        return Enemy(
            name: name,
            hp: hp,
            maxHP: maxHP,
            attackPower: attackPower,
            type: type
        )
    }
}
