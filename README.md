# DnD (Generative Dungeons and Dragons)

An AI-powered Dungeons & Dragons iOS application that acts as your personal Dungeon Master. It leverages Apple's on-device Foundation Models to dynamically generate dark-fantasy adventures, complete with engaging NPC dialogue, immersive scenes, and meaningful player choices.

## How the Game Works

The game follows a structured narrative loop mimicking a tabletop role-playing experience:

1. **Campaign Generation:** Start a new adventure with unique quest goals and story seeds. 
2. **Interactive Storytelling:** The AI generates rich scene descriptions and dialogue, creating a vivid dark-fantasy world.
3. **Player Choices:** Every turn, you're presented with a set of actions. The decisions you make actively shape the narrative path.
4. **Ability Checks & Dice Rolls:** Actions frequently require ability checks (e.g., Strength, Dexterity, Charisma). Behind the scenes, a d20 is rolled, and your character's stat modifiers are applied against a dynamic Difficulty Class (DC). 
5. **Consequences:** Success progresses you towards your quest's ultimate goal, while failures introduce setbacks, combat encounters, or HP damage.
6. **Progression:** Complete quests successfully to earn XP and level up as you progress through multi-turn story arcs.

## Technology Stack

- **SwiftUI**: Modern, dynamic user interface crafted for iOS.
- **Foundation Models**: Utilizes on-device LLMs via `LanguageModelSession` for fast, localized, and private story generation.
