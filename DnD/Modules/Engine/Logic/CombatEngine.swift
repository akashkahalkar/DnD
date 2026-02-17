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
    
    static func calculateEnemyAttack(
        enemy: Enemy,
        player: inout Player,
        damageMultiplier: Double = 1.0,
        flatReduction: Int = 0
    ) -> (message: String, damage: Int) {
        let roll = DiceRoller.roll(.d6, bonus: enemy.attackPower / 2) // Simple enemy attack logic
        let scaled = max(1, Int(Double(roll.total) * damageMultiplier))
        let adjusted = max(1, scaled - max(0, flatReduction))
        player.hp = max(0, player.hp - adjusted)
        
        return ("\(enemy.name) attacks and deals \(adjusted) damage to you!", adjusted)
    }
}
