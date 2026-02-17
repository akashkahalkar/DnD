import Foundation

enum RunPhase: String, Codable {
    case narrative
    case combat
    case levelUp
    case gameOver
    case victory
    case questFailed
}

enum QuestOutcome: String, Codable {
    case inProgress
    case success
    case failure
}

struct RunState: Codable {
    var phase: RunPhase
    var turnNumber: Int
    var questOutcome: QuestOutcome?
    var activeEnemy: Enemy?
}

struct CombatState: Codable {
    var enemy: Enemy
    var playerTurn: Bool
    var lastActionResult: String?
    var roundNumber: Int
}

struct ProgressionState: Codable {
    var xp: Int
    var level: Int
    var unspentPoints: Int
    var recentRewards: [String]
}
