## Beta Readiness Gap Audit: Text-Based DnD (Playable Vertical Slice)

  ### Summary
  Current app has a strong prototype core (`NarrativeTestView`, guided story generation, basic battle screen, persistence), but it is still a **test harness**, not yet a cohesive player-facing beta.
  Given your chosen target (**Playable Vertical Slice**, **Light Tactical Combat**), the biggest gaps are: missing entry flow screens, incomplete combat loop integration, weak progression/reward loop, and missing release-quality UX/compliance surfaces.

  ### Current State (What Exists)
  1. Narrative scene generation and choice loop in `NarrativeTestView`.
  2. Roll resolution state.
  3. Combat state trigger and `BattleScreen` placeholder.
  4. Game over state exists.
  5. Persistence service exists and saves player/story snapshots.
  6. Foundation Models guided generation + transcript trimming logic.

  ### Missing Screens (Player-Facing)
  1. **Home / Title Screen**
  - `New Game`
  - `Continue`
  - `Settings`
  - `About/Version`

  2. **Run Selection / Continue Screen**
  - Show latest run metadata (turn, HP, timestamp).
  - Option to start fresh run without deleting older data.

  3. **Character Creation Screen**
  - Name entry.
  - Ability point distribution UI (you now have enum-based abilities).
  - Optional class/archetype pick for flavor/perks.

  4. **Objective / Quest Journal Screen**
  - Current quest objective.
  - Quest status (`in_progress/success/failure`) surfaced from model output.
  - Prior scene recap.

  5. **Playable Combat Screen (Replace placeholder battle)**
  - Enemy card with stats.
  - Player actions (`Attack`, `Defend`, `Ability`, `Item`, `Flee`).
  - Turn log and outcome display.
  - End-of-combat CTA back to narrative.

  6. **Combat Result / Rewards Screen**
  - XP gain.
  - Loot/reward.
  - HP/status summary.
  - `Continue Adventure` action.

  7. **Level-Up / Stat Allocation Screen**
  - Trigger when XP threshold crossed.
  - Spend points into abilities/perks.
  - Confirm changes before applying.

  8. **Inventory Screen**
  - Items list.
  - Consumable use (healing potion etc.).
  - Equipment/effect summary.

  9. **Victory / Ending Screen**
  - Distinct from game-over defeat.
  - Show quest outcome and summary stats.

  10. **Settings Screen**
  - Text speed / animation toggles.
  - Sound/music toggle (even if placeholders).
  - Reset run / clear save.

  11. **Onboarding / Tutorial Overlay**
  - Explain choices, rolls, combat transitions, and win/loss conditions.

  ### Missing Gameplay Components (Non-Screen)
  1. **Deterministic Combat Engine Integration**
  - `CombatEngine` and `Enemy` are not driving real combat turns yet.
  - Current “resolve battle” uses random incoming damage shortcut.

  2. **Enemy Generation + Stats Pipeline**
  - Need enemy type + HP + attack power tied to `is_combat` scene context.
  - Show enemy strengths/weaknesses in combat UI.

  3. **Progression Loop**
  - `xpChange` is present but not wired.
  - Need XP thresholds, level progression, reward mapping.

  4. **Run Completion Rules**
  - LLM instruction currently forces 8-turn arc, but game engine should own hard stop/final checks.
  - Add app-side terminal validator to prevent endless loops.

  5. **Narrative-State Contract Hardening**
  - Ensure every scene has valid combat/game-over semantics.
  - Guardrails for malformed choices or empty arrays.

  6. **Save/Load Model Completion**
  - Add explicit `run state` fields: current phase, active enemy, turn index, quest status.
  - Resume into exact UI state, not just player snapshot.

  7. **Balance & Tuning Layer**
  - Damage curves, roll DC ranges, enemy scaling by turn.
  - Prevent unwinnable spikes and trivial runs.

  ### Missing Beta Release Components (App Store/TestFlight Quality)
  1. **Crash/Error UX**
  - Friendly recovery screens for model unavailable/rate/context failures.
  - Retry + fallback strategy surfaced to player.

  2. **Observability**
  - Lightweight analytics/events for key funnel points:
    - app start
    - new/continue
    - combat start/end
    - run end
    - model failure categories

  3. **Accessibility**
  - Dynamic Type support audit.
  - VoiceOver labels for action buttons/cards.
  - Color contrast checks.

  4. **Legal/Meta**
  - Credits/licenses screen (fonts + AI features).
  - Privacy policy link and in-app disclosure for on-device AI behavior.
  - TestFlight feedback entry point.

  5. **Content Quality Pass**
  - Replace “test” labels and debug wording.
  - Unified copywriting tone across screens.

  6. **Testing**
  - No meaningful automated tests currently.
  - Add unit tests for:
    - state transitions
    - combat outcome calculations
    - persistence round-trip
    - context-window recovery path

  ### Public Interface / Type Additions Needed
  1. `RunState` model
  - `phase` (`narrative`, `combat`, `levelUp`, `gameOver`, `victory`)
  - `turnNumber`
  - `questOutcome`
  - `activeEnemy`

  2. `CombatState` model
  - `enemy`
  - `playerTurn`
  - `lastActionResult`
  - `roundNumber`

  3. `ProgressionState` model
  - `xp`
  - `level`
  - `unspentPoints`
  - `recentRewards`

  4. `DataService` additions
  - `loadRunState()`
  - `saveRunState(...)`
  - `saveCombatState(...)`
  - `completeRun(...)`

  ### Prioritized Scope for Playable Beta (Recommended)
  1. **P0 (Must Ship for playable demo)**
  - Home screen, New/Continue flow, Character creation.
  - Real combat loop screen with 3-5 actions and enemy stats.
  - Reward/XP + level-up screen.
  - Victory + defeat endpoints.
  - Resume run from save.
  - Basic settings + onboarding.

  2. **P1 (Strong beta quality)**
  - Quest journal.
  - Inventory with usable items.
  - Better error/retry UX for model failures.
  - Accessibility baseline.

  3. **P2 (Post-beta polish)**
  - Advanced combat abilities/status effects.
  - Rich enemy variety balancing.
  - Localization and broader content packs.

  ### Acceptance Criteria (Playable Demo)
  1. Player can start new run, create character, and play 10-20 minutes without dead ends.
  2. At least one combat encounter occurs with explicit tactical choices.
  3. Run always reaches a valid ending (`victory` or `game over`) within designed turn range.
  4. Continue flow resumes exact run phase after app relaunch.
  5. No critical blocker when Foundation Models unavailable (fallback path remains playable).

  ### Assumptions and Defaults Chosen
  1. Scope optimized for **Playable Vertical Slice**.
  2. Combat depth set to **Light Tactical** (3-5 actions, simple turn loop).
  3. Single-player, on-device only, no account system for beta.
  4. One polished narrative arc prioritized over broad feature breadth.


