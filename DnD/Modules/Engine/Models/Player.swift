import Foundation

struct Player: Codable {
    var name: String
    var hp: Int
    var maxHP: Int
    var strength: Int
    var charisma: Int
    var inventory: [String] = []
    
    var isAlive: Bool {
        hp > 0
    }
}
