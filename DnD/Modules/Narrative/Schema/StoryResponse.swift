import Foundation

struct NPCLine: Codable {
    let speaker: String
    let line: String
}

struct StoryResponse: Codable {
    let sceneDescription: String
    let npcDialogue: [NPCLine]
    let choices: [String]
    let requiresRoll: String? // "stealth", "strength", etc.
    
    enum CodingKeys: String, CodingKey {
        case sceneDescription = "scene_description"
        case npcDialogue = "npc_dialogue"
        case choices
        case requiresRoll = "requires_roll"
    }
}
