import Foundation

enum DiceType: Int {
    case d4 = 4
    case d6 = 6
    case d8 = 8
    case d10 = 10
    case d12 = 12
    case d20 = 20
}

struct DiceResult {
    let roll: Int
    let type: DiceType
    let bonus: Int
    
    var total: Int {
        roll + bonus
    }
}

struct DiceRoller {
    static func roll(_ type: DiceType, bonus: Int = 0) -> DiceResult {
        let roll = Int.random(in: 1...type.rawValue)
        return DiceResult(roll: roll, type: type, bonus: bonus)
    }
    
    static func advantageRoll(_ type: DiceType, bonus: Int = 0) -> DiceResult {
        let roll1 = Int.random(in: 1...type.rawValue)
        let roll2 = Int.random(in: 1...type.rawValue)
        return DiceResult(roll: max(roll1, roll2), type: type, bonus: bonus)
    }
    
    static func disadvantageRoll(_ type: DiceType, bonus: Int = 0) -> DiceResult {
        let roll1 = Int.random(in: 1...type.rawValue)
        let roll2 = Int.random(in: 1...type.rawValue)
        return DiceResult(roll: min(roll1, roll2), type: type, bonus: bonus)
    }
}
