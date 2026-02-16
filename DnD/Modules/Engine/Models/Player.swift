import Foundation

enum Ability: String, CaseIterable, Codable, Hashable {
    case strength
    case dexterity
    case constitution
    case intelligence
    case wisdom
    case charisma
    
    static let baselineScore = 10
    static let defaultUnspentPoints = 5
    
    static var defaultScores: [Ability: Int] {
        Dictionary(uniqueKeysWithValues: Ability.allCases.map { ($0, baselineScore) })
    }
}

struct Player: Codable, Hashable {
    var name: String
    var hp: Int
    var maxHP: Int
    var archetype: String
    var abilityScores: [Ability: Int]
    var unspentAbilityPoints: Int
    var inventory: [String] = []

    static let defaultMaxHP = 45
    static let defaultArchetype = "Wanderer"
    
    init(
        name: String,
        hp: Int,
        maxHP: Int,
        archetype: String = Player.defaultArchetype,
        abilityScores: [Ability: Int] = Ability.defaultScores,
        unspentAbilityPoints: Int = Ability.defaultUnspentPoints,
        inventory: [String] = []
    ) {
        self.name = name
        self.hp = hp
        self.maxHP = maxHP
        self.archetype = archetype
        self.abilityScores = abilityScores
        self.unspentAbilityPoints = unspentAbilityPoints
        self.inventory = inventory
    }
    
    var isAlive: Bool {
        hp > 0
    }
    
    func abilityScore(for ability: Ability) -> Int {
        abilityScores[ability] ?? Ability.baselineScore
    }
    
    func abilityModifier(for ability: Ability) -> Int {
        let score = abilityScore(for: ability)
        return (score - Ability.baselineScore) / 2
    }
    
    mutating func applyAbilityPoint(to ability: Ability) -> Bool {
        guard unspentAbilityPoints > 0 else { return false }
        abilityScores[ability, default: Ability.baselineScore] += 1
        unspentAbilityPoints -= 1
        return true
    }
    
    mutating func setAbilityScore(_ value: Int, for ability: Ability) {
        abilityScores[ability] = max(1, value)
    }
    
    mutating func updateHP(_ newHP: Int) {
        hp = newHP
    }
}
