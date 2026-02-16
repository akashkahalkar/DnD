import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

struct NPCLine: Codable {
    let speaker: String
    let line: String
}

struct StoryResponse: Codable {
    let sceneDescription: String
    let npcDialogue: [NPCLine]
    let choices: [String]
    let requiresRoll: String? // "stealth", "strength", etc.
    let isCombat: Bool?
    var xpChange: Int?
    let questOutcome: String? // "success", "failure", "in_progress"
    
    enum CodingKeys: String, CodingKey {
        case sceneDescription = "scene_description"
        case npcDialogue = "npc_dialogue"
        case choices
        case requiresRoll = "requires_roll"
        case isCombat = "is_combat"
        case questOutcome = "quest_outcome"
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable(description: "An NPC line with speaker and dialogue")
struct GuidedNPCLine {
    var speaker: String
    var line: String
}

@available(iOS 26.0, *)
@Generable(description: "Ability types used for checks")
enum GuidedAbility: String {
    case strength
    case dexterity
    case constitution
    case intelligence
    case wisdom
    case charisma
}

@available(iOS 26.0, *)
@Generable(description: "Structured scene payload for the DnD narrative engine")
struct GuidedStoryResponse {
    @Guide(description: "A vivid dark-fantasy scene in 2-3 sentences")
    var sceneDescription: String
    
    @Guide(description: "0 to 2 NPC dialogue lines")
    var npcDialogue: [GuidedNPCLine]
    
    @Guide(description: "Exactly 3 meaningful player choices", .count(3))
    var choices: [String]
    
    @Guide(description: "Use nil by default; only set for uncertain and high-stakes outcomes")
    var requiresRoll: GuidedAbility?
    
    var isCombat: Bool?
    
    @Guide(description: "One of: success, failure, in_progress")
    var questOutcome: String?
}

@available(iOS 26.0, *)
extension GuidedStoryResponse {
    func toStoryResponse() -> StoryResponse {
        StoryResponse(
            sceneDescription: sceneDescription,
            npcDialogue: npcDialogue.map { NPCLine(speaker: $0.speaker, line: $0.line) },
            choices: choices,
            requiresRoll: requiresRoll?.rawValue,
            isCombat: isCombat,
            xpChange: nil, // To be filled by orchestrator
            questOutcome: questOutcome
        )
    }
}
#endif
