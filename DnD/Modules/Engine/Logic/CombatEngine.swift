import Foundation

struct CombatAction {
    let name: String
    let damageDice: DiceType
    let bonus: Int
}

class CombatEngine {
    static func calculatePlayerAttack(player: Player, enemy: inout Enemy, action: CombatAction) -> String {
        let roll = DiceRoller.roll(action.damageDice, bonus: action.bonus)
        enemy.hp = max(0, enemy.hp - roll.total)
        
        return "You use \(action.name) and deal \(roll.total) damage to \(enemy.name)!"
    }
    
    static func calculateEnemyAttack(enemy: Enemy, player: inout Player) -> String {
        let roll = DiceRoller.roll(.d6, bonus: enemy.attackPower / 2) // Simple enemy attack logic
        player.hp = max(0, player.hp - roll.total)
        
        return "\(enemy.name) attacks and deals \(roll.total) damage to you!"
    }
}
