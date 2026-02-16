import Foundation
import SwiftData

@Model
final class RunStateData {
    var phaseRaw: String
    var turnNumber: Int
    var questOutcomeRaw: String?
    var activeEnemyName: String?
    var activeEnemyType: String?
    var activeEnemyHP: Int?
    var activeEnemyMaxHP: Int?
    var activeEnemyAttackPower: Int?
    var creationDate: Date

    init(
        phaseRaw: String,
        turnNumber: Int,
        questOutcomeRaw: String? = nil,
        activeEnemyName: String? = nil,
        activeEnemyType: String? = nil,
        activeEnemyHP: Int? = nil,
        activeEnemyMaxHP: Int? = nil,
        activeEnemyAttackPower: Int? = nil
    ) {
        self.phaseRaw = phaseRaw
        self.turnNumber = turnNumber
        self.questOutcomeRaw = questOutcomeRaw
        self.activeEnemyName = activeEnemyName
        self.activeEnemyType = activeEnemyType
        self.activeEnemyHP = activeEnemyHP
        self.activeEnemyMaxHP = activeEnemyMaxHP
        self.activeEnemyAttackPower = activeEnemyAttackPower
        self.creationDate = Date()
    }
}

@Model
final class CombatStateData {
    var enemyName: String
    var enemyType: String
    var enemyHP: Int
    var enemyMaxHP: Int
    var enemyAttackPower: Int
    var playerTurn: Bool
    var lastActionResult: String?
    var roundNumber: Int
    var creationDate: Date

    init(
        enemyName: String,
        enemyType: String,
        enemyHP: Int,
        enemyMaxHP: Int,
        enemyAttackPower: Int,
        playerTurn: Bool,
        lastActionResult: String? = nil,
        roundNumber: Int
    ) {
        self.enemyName = enemyName
        self.enemyType = enemyType
        self.enemyHP = enemyHP
        self.enemyMaxHP = enemyMaxHP
        self.enemyAttackPower = enemyAttackPower
        self.playerTurn = playerTurn
        self.lastActionResult = lastActionResult
        self.roundNumber = roundNumber
        self.creationDate = Date()
    }
}

@Model
final class ProgressionStateData {
    var xp: Int
    var level: Int
    var unspentPoints: Int
    var recentRewards: [String]
    var creationDate: Date

    init(
        xp: Int,
        level: Int,
        unspentPoints: Int,
        recentRewards: [String] = []
    ) {
        self.xp = xp
        self.level = level
        self.unspentPoints = unspentPoints
        self.recentRewards = recentRewards
        self.creationDate = Date()
    }
}
