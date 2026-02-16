import Combine
import SwiftUI

struct NarrativeTestView: View {
    let startMode: NarrativeStartMode
    let playerOverride: Player?
    @StateObject private var viewModel: NarrativeTestViewModel
    @State private var showModelAlert = false
    @State private var hasTriggeredStart = false

    init(startMode: NarrativeStartMode = .newGame, playerOverride: Player? = nil) {
        self.startMode = startMode
        self.playerOverride = playerOverride
        _viewModel = StateObject(wrappedValue: NarrativeTestViewModel(playerOverride: playerOverride))
    }
    
    var body: some View {
        ZStack {
            FantasyBackground()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("NARRATIVE ENGINE TEST")
                            .font(.fantasyTitle)
                            .foregroundColor(.accentGold)
                        
                        Text("Dry Run: Story Generation Flow")
                            .font(.fantasyCaption)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 40)
                    
                    // Foundation Model Status Alert
                    if !viewModel.isFoundationModelAvailable {
                        FantasyPanel {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.accentGold)
                                    .font(.system(size: 20))
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Foundation Models Unavailable")
                                        .font(.fantasyBodyBold)
                                        .foregroundColor(.textPrimary)
                                    
                                    Text("Using mock responses. Requires iOS 26+ and Apple Intelligence.")
                                        .font(.fantasyCaption)
                                        .foregroundColor(.textSecondary)
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Player Info Card
                    FantasyPanel {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.player.name)
                                    .font(.fantasyBodyBold)
                                    .foregroundColor(.textPrimary)
                                
                                Text("HP: \(viewModel.player.hp)/\(viewModel.player.maxHP)")
                                    .font(.fantasyCaption)
                                    .foregroundColor(.accentNeon)
                            }
                            
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    if let story = viewModel.currentStory {
                        // Scene Content
                        if viewModel.state == .sceneDisplay {
                            SceneDisplayView(story: story, viewModel: viewModel)
                        }
                        else if viewModel.state == .combat {
                            if let combatState = viewModel.combatState {
                                BattleScreen(
                                    player: $viewModel.player,
                                    combatState: Binding(
                                        get: { combatState },
                                        set: { viewModel.combatState = $0 }
                                    ),
                                    onCombatEnd: viewModel.handleCombatEnd,
                                    onCombatUpdate: viewModel.persistCombatState
                                )
                                .frame(height: 640)
                                .padding(.horizontal, 16)
                            }
                        }
                        else if case .resolving(let roll, let dc, let hpChange, let outcome) = viewModel.state {
                            ResolutionView(roll: roll, dc: dc, hpChange: hpChange, outcome: outcome) {
                                viewModel.continueToNextScene()
                            }
                        }
                    }

                    if case .combatRewards(let xp, let rewards) = viewModel.state {
                        CombatRewardsView(xpGained: xp, rewards: rewards) {
                            viewModel.handleRewardsContinue()
                        }
                        .padding(.horizontal, 16)
                    }

                    if viewModel.state == .levelUp {
                        LevelUpView(
                            player: $viewModel.player,
                            progression: $viewModel.progression
                        ) {
                            viewModel.handleLevelUpConfirm()
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Loading State
                    if viewModel.state == .loading {
                        FantasyPanel {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .tint(.accentMagic)
                                    .scaleEffect(1.5)
                                
                                Text("Generating story...")
                                    .font(.fantasyBody)
                                    .foregroundColor(.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Error State
                    if case .error(let message) = viewModel.state {
                        FantasyPanel {
                            VStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.accentDanger)
                                
                                Text(message)
                                    .font(.fantasyBody)
                                    .foregroundColor(.textPrimary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Game Over State
                    if case .gameOver(let message) = viewModel.state {
                        FantasyPanel {
                            VStack(spacing: 12) {
                                Image(systemName: "xmark.octagon.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(.accentDanger)
                                
                                Text("GAME OVER")
                                    .font(.fantasyTitle)
                                    .foregroundColor(.accentDanger)
                                
                                Text(message)
                                    .font(.fantasyBody)
                                    .foregroundColor(.textPrimary)
                                    .multilineTextAlignment(.center)
                                
                                FantasyPrimaryButton(title: "START NEW RUN") {
                                    viewModel.startNewGame(resetPlayer: true)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // Start/Restart Button
                    if viewModel.currentStory == nil && viewModel.state != .loading {
                        FantasyPrimaryButton(title: startMode == .newGame ? "START ADVENTURE" : "RESUME ADVENTURE") {
                            viewModel.startNewGame(resetPlayer: startMode == .newGame)
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    // History Count
                    if viewModel.storyHistory.count > 0 {
                        Text("Turn \(viewModel.storyHistory.count) of 8")
                            .font(.fantasyCaption)
                            .foregroundColor(.textMuted)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            StartupDiagnostics.mark("NarrativeTestView onAppear")
            viewModel.checkFoundationModelAvailability()
            guard !hasTriggeredStart else { return }
            hasTriggeredStart = true
            if startMode == .newGame {
                StartupDiagnostics.mark("NarrativeTestView triggering initial startNewGame")
                viewModel.startNewGame(resetPlayer: true)
            }
        }
        .alert("Foundation Models Not Available", isPresented: $showModelAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Apple Foundation Models require iOS 26+ and a device with Apple Intelligence (iPhone 15 Pro or later). The app will use mock story responses for testing.")
        }
    }
    
    // MARK: - Subviews
    
    struct SceneDisplayView: View {
        let story: StoryResponse
        @ObservedObject var viewModel: NarrativeTestViewModel
        
        var body: some View {
            VStack(spacing: 24) {
                // Scene Description
                FantasyPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("SCENE")
                            .font(.fantasyCaption)
                            .foregroundColor(.accentGold)
                            .tracking(2)
                        
                        Text(story.sceneDescription)
                            .font(.fantasyBody)
                            .foregroundColor(.textPrimary)
                            .lineSpacing(4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)
                
                // NPC Dialogue
                if !story.npcDialogue.isEmpty {
                    ForEach(story.npcDialogue.indices, id: \.self) { index in
                        let dialogue = story.npcDialogue[index]
                        FantasyPanel {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.accentPurple)
                                    Text(dialogue.speaker)
                                        .font(.fantasyBodyBold)
                                        .foregroundColor(.accentPurple)
                                }
                                
                                Text("\"\(dialogue.line)\"")
                                    .font(.fantasyBody)
                                    .foregroundColor(.textPrimary)
                                    .italic()
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                
                // Roll Required Indicator
                if let rollType = story.requiresRoll {
                    HStack {
                        Image(systemName: "dice.fill")
                            .foregroundColor(.accentGold)
                        Text("Requires \(rollType.uppercased()) check")
                            .font(.fantasyCaption)
                            .foregroundColor(.accentGold)
                    }
                    .padding(.horizontal, 16)
                }
                
                // Player Choices
                VStack(spacing: 12) {
                    Text("WHAT DO YOU DO?")
                        .font(.fantasyCaption)
                        .foregroundColor(.textSecondary)
                        .tracking(2)
                    
                    ForEach(story.choices.indices, id: \.self) { index in
                        Button(action: {
                            viewModel.selectChoice(story.choices[index])
                        }) {
                            HStack {
                                Text(story.choices[index])
                                    .font(.fantasyBody)
                                    .foregroundColor(.textPrimary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                                
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.accentMagic)
                            }
                            .padding()
                            .glassBackground(cornerRadius: 16)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    // MARK: - ViewModel
    
    @MainActor
    class NarrativeTestViewModel: ObservableObject {

        // MARK: - State Machine
        
        enum NarrativeState: Equatable {
            case sceneDisplay
            case resolving(roll: DiceResult, dc: Int, hpChange: Int, outcome: Bool)
            case combat
            case combatRewards(xp: Int, rewards: [String])
            case levelUp
            case gameOver(String)
            case loading
            case error(String)
            
            static func == (lhs: NarrativeState, rhs: NarrativeState) -> Bool {
                switch (lhs, rhs) {
                case (.sceneDisplay, .sceneDisplay), (.loading, .loading), (.combat, .combat):
                    return true
                case (.levelUp, .levelUp):
                    return true
                case (.combatRewards(let x1, let r1), .combatRewards(let x2, let r2)):
                    return x1 == x2 && r1 == r2
                case (.error(let a), .error(let b)):
                    return a == b
                case (.gameOver(let a), .gameOver(let b)):
                    return a == b
                case (.resolving(let r1, let d1, let h1, let o1), .resolving(let r2, let d2, let h2, let o2)):
                    return r1.total == r2.total && d1 == d2 && h1 == h2 && o1 == o2
                default:
                    return false
                }
            }
        }
        
        @Published var state: NarrativeState = .sceneDisplay
        @Published var currentStory: StoryResponse? = nil
        @Published var storyHistory: [StoryResponse] = []
        @Published var isFoundationModelAvailable = false
        @Published var player: Player
        @Published var progression: ProgressionState
        @Published var combatState: CombatState?
        private let defaultPlayer: Player
        
        // Context for next story generation during resolution phase
        private struct PendingResolution {
            let choice: String
            let rollResult: DiceResult
            let dc: Int
            let hpChange: Int
            let outcome: Bool
        }
        
        private var pendingResolution: PendingResolution?
        
        private let orchestrator = NarrativeOrchestrator()
        private let dataService = DataService.shared
        private var currentGameData: GameData?
        
        init(playerOverride: Player? = nil) {
            StartupDiagnostics.mark("NarrativeTestViewModel init")
            let basePlayer = playerOverride ?? Player(
                name: "Aldric the Brave",
                hp: Player.defaultMaxHP,
                maxHP: Player.defaultMaxHP,
                archetype: "Warden",
                abilityScores: [
                    .strength: 14,
                    .dexterity: 11,
                    .constitution: 13,
                    .intelligence: 10,
                    .wisdom: 10,
                    .charisma: 12
                ],
                unspentAbilityPoints: 5,
                inventory: ["Longsword", "Health Potion", "Torch"]
            )
            self.defaultPlayer = basePlayer
            
            if playerOverride == nil, let latestGame = dataService.fetchLatestGame() {
                self.currentGameData = latestGame
                self.player = dataService.player(from: latestGame)
                if let savedProgression = dataService.loadProgressionState(from: latestGame) {
                    self.progression = savedProgression
                } else {
                    self.progression = ProgressionState(xp: 0, level: 1, unspentPoints: 0, recentRewards: [])
                }
            } else {
                self.player = basePlayer
                self.progression = ProgressionState(xp: 0, level: 1, unspentPoints: 0, recentRewards: [])
            }
        }
        
        func checkFoundationModelAvailability() {
            StartupDiagnostics.mark("Checking Foundation Models availability")
            if #available(iOS 26.0, *) {
#if canImport(FoundationModels)
                isFoundationModelAvailable = true
#else
                isFoundationModelAvailable = false
#endif
            } else {
                isFoundationModelAvailable = false
            }
        }
        
        func startNewGame(resetPlayer: Bool = false) {
            let requestStart = ProcessInfo.processInfo.systemUptime
            StartupDiagnostics.mark("startNewGame requested")
            Task {
                state = .loading
                if resetPlayer {
                    player = defaultPlayer
                    currentGameData = nil
                    currentStory = nil
                    storyHistory = []
                    combatState = nil
                    progression = ProgressionState(xp: 0, level: 1, unspentPoints: 0, recentRewards: [])
                }
                if player.hp <= 0 {
                    player.hp = player.maxHP
                }
                
                do {
                    let story = try await orchestrator.startNewGame(player: player, turnNumber: 1)
                    currentStory = story
                    storyHistory = [story]
                    currentGameData = dataService.saveGame(player: player)
                    if let gameData = currentGameData {
                        dataService.appendStory(to: gameData, scene: story.sceneDescription, choice: nil)
                        dataService.saveProgressionState(progression, to: gameData)
                    }
                    updateStateForStory(story)
                    let elapsed = ProcessInfo.processInfo.systemUptime - requestStart
                    let formatted = String(format: "%.3f", elapsed)
                    StartupDiagnostics.mark("startNewGame completed in \(formatted)s")
                } catch {
                    state = .error("Failed to start game: \(error.localizedDescription)")
                    StartupDiagnostics.mark("startNewGame failed: \(error.localizedDescription)")
                }
            }
        }
        
        func selectChoice(_ choice: String) {
            Task {
                // 1. Determine Initial State
                // If a roll is required, we go straight to resolution (no loading).
                // If no roll, we go to loading.
                
                do {
                    // Check if this choice requires a dice roll
                    if let rollType = currentStory?.requiresRoll {
                        // 2. Perform Roll
                        let modifier = orchestrator.getAbilityModifier(for: rollType, player: player)
                        let rollResult = DiceRoller.roll(.d20, bonus: modifier)
                        
                        // 3. Resolve Outcome (Deterministic & Immediate)
                        let (hpChange, dc, outcome) = orchestrator.resolveAction(rollResult: rollResult)
                        
                        // 4. Apply Consequence Immediately
                        player.hp = max(0, player.hp + hpChange)
                        persistPlayerState()
                        
                        // 5. Store Resolution Context for Next Step (AI Generation)
                        self.pendingResolution = PendingResolution(
                            choice: choice,
                            rollResult: rollResult,
                            dc: dc,
                            hpChange: hpChange,
                            outcome: outcome
                        )
                        
                        // 6. Transition to Resolution State (Shows Roll UI)
                        // This happens IMMEDIATELY, no AI call yet
                        state = .resolving(roll: rollResult, dc: dc, hpChange: hpChange, outcome: outcome)
                        
                    } else {
                        // No roll needed - standard flow (AI generates immediately)
                        state = .loading
                        let nextTurnNumber = storyHistory.count + 1
                        let story = try await orchestrator.processPlayerChoice(
                            choice: choice,
                            player: player,
                            turnNumber: nextTurnNumber
                        )
                        currentStory = story
                        storyHistory.append(story)
                        persistPlayerState()
                        persistStory(scene: story.sceneDescription, choice: choice)
                        updateStateForStory(story)
                    }
                } catch {
                    state = .error("Failed to process choice: \(error.localizedDescription)")
                }
            }
        }
        
        func continueToNextScene() {
            guard let resolution = pendingResolution else { return }
            
            Task {
                state = .loading
                
                do {
                    // Generate story based on the resolved outcome
                    let nextTurnNumber = storyHistory.count + 1
                    let story = try await orchestrator.generateResolvedStory(
                        choice: resolution.choice,
                        player: player,
                        turnNumber: nextTurnNumber,
                        rollResult: resolution.rollResult,
                        dc: resolution.dc,
                        hpChange: resolution.hpChange,
                        outcomeDescription: resolution.outcome ? "action succeeded" : "action failed"
                    )
                
                    
                    currentStory = story
                    storyHistory.append(story)
                    pendingResolution = nil
                    persistPlayerState()
                    persistStory(scene: story.sceneDescription, choice: resolution.choice)
                    updateStateForStory(story)
                    
                } catch {
                    state = .error("Failed to generate next scene: \(error.localizedDescription)")
                }
            }
        }
        
        private func updateStateForStory(_ story: StoryResponse) {
            if player.hp <= 0 {
                combatState = nil
                state = .gameOver("The campaign has reached its end.")
                persistRunState(phase: .gameOver)
                return
            }

            if story.isCombat == true {
                if combatState == nil {
                    combatState = buildCombatState(turnNumber: storyHistory.count)
                }
                state = .combat
                persistRunState(phase: .combat, activeEnemy: combatState?.enemy)
                return
            }

            combatState = nil
            state = .sceneDisplay
            persistRunState(phase: .narrative, questOutcome: questOutcome(from: story.questOutcome))
        }

        func handleCombatEnd(_ outcome: CombatOutcome) {
            combatState = nil

            switch outcome {
            case .defeat:
                state = .gameOver("You were defeated in battle. Your journey ends here.")
                persistRunState(phase: .gameOver)
            case .victory, .fled:
                if outcome == .victory {
                    let rewards = grantCombatRewards(turnNumber: storyHistory.count)
                    state = .combatRewards(xp: rewards.xpGained, rewards: rewards.items)
                } else {
                    continueAfterCombat(
                        choice: "The hero flees the battle to fight another day."
                    )
                }
            }
        }

        func persistCombatState() {
            guard let gameData = currentGameData, let combatState else { return }
            let runState = RunState(
                phase: .combat,
                turnNumber: storyHistory.count,
                questOutcome: questOutcome(from: currentStory?.questOutcome),
                activeEnemy: combatState.enemy
            )
            dataService.saveRunState(runState, combatState: combatState, to: gameData)
        }

        func handleRewardsContinue() {
            if progression.unspentPoints > 0 {
                state = .levelUp
                persistRunState(phase: .levelUp)
                return
            }
            continueAfterCombat(choice: "The hero prevails in combat and presses onward.")
        }

        func handleLevelUpConfirm() {
            persistPlayerState()
            persistProgressionState()
            continueAfterCombat(choice: "Empowered by growth, the hero presses onward.")
        }

        private func continueAfterCombat(choice: String) {
            state = .loading
            Task {
                do {
                    let nextTurnNumber = storyHistory.count + 1
                    let story = try await orchestrator.processPlayerChoice(
                        choice: choice,
                        player: player,
                        turnNumber: nextTurnNumber
                    )
                    currentStory = story
                    storyHistory.append(story)
                    persistPlayerState()
                    persistStory(scene: story.sceneDescription, choice: choice)
                    updateStateForStory(story)
                } catch {
                    state = .error("Failed to continue after combat: \(error.localizedDescription)")
                }
            }
        }

        private func buildCombatState(turnNumber: Int) -> CombatState {
            let enemy = generateEnemy(turnNumber: max(1, turnNumber))
            return CombatState(
                enemy: enemy,
                playerTurn: true,
                lastActionResult: nil,
                roundNumber: 1
            )
        }

        private func generateEnemy(turnNumber: Int) -> Enemy {
            if turnNumber >= 7 {
                return Enemy(
                    name: "Dread Revenant",
                    hp: 42,
                    maxHP: 42,
                    attackPower: 10,
                    type: "Revenant Knight"
                )
            } else if turnNumber >= 4 {
                return Enemy(
                    name: "Grim Marauder",
                    hp: 30,
                    maxHP: 30,
                    attackPower: 7,
                    type: "Cult Enforcer"
                )
            } else {
                return Enemy(
                    name: "Crypt Stalker",
                    hp: 22,
                    maxHP: 22,
                    attackPower: 5,
                    type: "Ghoul"
                )
            }
        }

        private func persistRunState(phase: RunPhase, activeEnemy: Enemy? = nil, questOutcome: QuestOutcome? = nil) {
            guard let gameData = currentGameData else { return }
            let runState = RunState(
                phase: phase,
                turnNumber: storyHistory.count,
                questOutcome: questOutcome,
                activeEnemy: activeEnemy
            )
            dataService.saveRunState(runState, combatState: combatState, progressionState: progression, to: gameData)
        }

        private func persistProgressionState() {
            guard let gameData = currentGameData else { return }
            dataService.saveProgressionState(progression, to: gameData)
        }

        private func questOutcome(from rawValue: String?) -> QuestOutcome? {
            guard let rawValue else { return nil }
            switch rawValue {
            case "success":
                return .success
            case "failure":
                return .failure
            case "in_progress":
                return .inProgress
            default:
                return nil
            }
        }

        private func grantCombatRewards(turnNumber: Int) -> (xpGained: Int, items: [String]) {
            let baseXP = turnNumber >= 7 ? 50 : 25
            let xpGained = baseXP + Int.random(in: 5...15)
            progression.xp += xpGained

            let newLevel = levelForXP(progression.xp)
            if newLevel > progression.level {
                let gainedLevels = newLevel - progression.level
                progression.level = newLevel
                progression.unspentPoints += gainedLevels * 2
            }

            let rewards = rollLoot(turnNumber: turnNumber)
            if !rewards.isEmpty {
                player.inventory.append(contentsOf: rewards)
            }
            progression.recentRewards = rewards
            persistPlayerState()
            persistProgressionState()
            return (xpGained, rewards)
        }

        private func levelForXP(_ xp: Int) -> Int {
            switch xp {
            case 0..<50:
                return 1
            case 50..<120:
                return 2
            case 120..<200:
                return 3
            case 200..<300:
                return 4
            default:
                return 5
            }
        }

        private func rollLoot(turnNumber: Int) -> [String] {
            let roll = Int.random(in: 1...100)
            if roll < 40 {
                return []
            } else if roll < 75 {
                return ["Health Potion"]
            } else if roll < 90 {
                return ["Mana Tonic"]
            } else if turnNumber >= 7 {
                return ["Relic Shard"]
            } else {
                return ["Silver Charm"]
            }
        }
        
        private func persistPlayerState() {
            if currentGameData == nil {
                currentGameData = dataService.saveGame(player: player)
                return
            }
            
            if let gameData = currentGameData {
                dataService.updateGame(gameData, player: player)
            }
        }
        
        private func persistStory(scene: String, choice: String?) {
            if currentGameData == nil {
                currentGameData = dataService.saveGame(player: player)
            }
            
            if let gameData = currentGameData {
                dataService.appendStory(to: gameData, scene: scene, choice: choice)
            }
        }
    }
    
    // MARK: - Preview
    
    struct NarrativeTestView_Previews: PreviewProvider {
        static var previews: some View {
            NarrativeTestView()
        }
    }
}
