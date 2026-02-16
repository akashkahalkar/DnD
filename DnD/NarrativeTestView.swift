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
                            BattleScreen()
                                .frame(height: 520)
                                .padding(.horizontal, 16)
                            
                            FantasyPrimaryButton(title: "RESOLVE BATTLE") {
                                viewModel.resolveCombatAndContinue()
                            }
                            .padding(.horizontal, 16)
                        }
                        else if case .resolving(let roll, let dc, let hpChange, let outcome) = viewModel.state {
                            ResolutionView(roll: roll, dc: dc, hpChange: hpChange, outcome: outcome) {
                                viewModel.continueToNextScene()
                            }
                        }
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
            case gameOver(String)
            case loading
            case error(String)
            
            static func == (lhs: NarrativeState, rhs: NarrativeState) -> Bool {
                switch (lhs, rhs) {
                case (.sceneDisplay, .sceneDisplay), (.loading, .loading), (.combat, .combat):
                    return true
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
            } else {
                self.player = basePlayer
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
        
        func resolveCombatAndContinue() {
            Task {
                let incomingDamage = Int.random(in: 2...8)
                player.hp = max(0, player.hp - incomingDamage)
                persistPlayerState()
                
                if player.hp <= 0 {
                    state = .gameOver("You were defeated in battle. Your journey ends here.")
                    return
                }
                
                state = .loading
                do {
                    let nextTurnNumber = storyHistory.count + 1
                    let story = try await orchestrator.processPlayerChoice(
                        choice: "The battle concluded. The hero pushes forward.",
                        player: player,
                        turnNumber: nextTurnNumber
                    )
                    currentStory = story
                    storyHistory.append(story)
                    persistPlayerState()
                    persistStory(scene: story.sceneDescription, choice: "Resolve battle")
                    updateStateForStory(story)
                } catch {
                    state = .error("Failed to continue after combat: \(error.localizedDescription)")
                }
            }
        }
        
        private func updateStateForStory(_ story: StoryResponse) {
            if player.hp <= 0 || story.isGameOver == true {
                state = .gameOver("The campaign has reached its end.")
            } else if story.isCombat == true {
                state = .combat
            } else {
                state = .sceneDisplay
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
