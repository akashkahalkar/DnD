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
                ProgressionStateData.self
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
