import Foundation

struct Enemy: Codable {
    var name: String
    var hp: Int
    var maxHP: Int
    var attackPower: Int
    var type: String
    
    var isAlive: Bool {
        hp > 0
    }
}
