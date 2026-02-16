import SwiftUI
import Combine

struct HomeView: View {
    let onStartNew: () -> Void
    let onContinue: () -> Void
    let onSettings: () -> Void
    let onAbout: () -> Void

    @StateObject private var viewModel = RunSelectionViewModel()

    var body: some View {
        ZStack {
            FantasyBackground()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 12) {
                        Text("DUNGEONS & DESTINY")
                            .font(.fantasyTitleLarge)
                            .foregroundColor(.accentGold)
                            .multilineTextAlignment(.center)

                        Text("A dark-fantasy vertical slice")
                            .font(.fantasyCaption)
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 60)

                    FantasyPanel {
                        VStack(spacing: 12) {
                            Text("ADVENTURE STATUS")
                                .font(.fantasyCaption)
                                .foregroundColor(.accentGold)
                                .tracking(2)

                            if let summary = viewModel.latestRun {
                                VStack(spacing: 8) {
                                    Text(summary.playerName)
                                        .font(.fantasyBodyBold)
                                        .foregroundColor(.textPrimary)

                                    Text("HP: \(summary.hp)/\(summary.maxHP) • Turn \(summary.turnNumber)")
                                        .font(.fantasyCaption)
                                        .foregroundColor(.accentNeon)

                                    Text("Last played \(summary.lastPlayedText)")
                                        .font(.fantasyCaption)
                                        .foregroundColor(.textSecondary)
                                }
                            } else {
                                Text("No saved run yet. Start a new adventure.")
                                    .font(.fantasyBody)
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 16) {
                        FantasyPrimaryButton(title: "NEW GAME") {
                            onStartNew()
                        }

                        FantasySecondaryButton(title: "CONTINUE") {
                            onContinue()
                        }
                        .disabled(!viewModel.hasRun)
                        .opacity(viewModel.hasRun ? 1.0 : 0.5)
                    }
                    .padding(.horizontal, 16)

                    HStack(spacing: 12) {
                        FantasySecondaryButton(title: "SETTINGS") {
                            onSettings()
                        }
                        FantasySecondaryButton(title: "ABOUT") {
                            onAbout()
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}

@MainActor
final class RunSelectionViewModel: ObservableObject {
    struct RunSummary: Identifiable {
        let id = UUID()
        let playerName: String
        let hp: Int
        let maxHP: Int
        let turnNumber: Int
        let lastPlayedText: String
    }

    @Published var latestRun: RunSummary?
    @Published var hasRun: Bool = false

    private let dataService = DataService.shared

    func refresh() {
        guard let gameData = dataService.fetchLatestGame() else {
            latestRun = nil
            hasRun = false
            return
        }

        let lastPlayedDate = gameData.storyHistory.last?.timestamp ?? gameData.creationDate
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        let turnNumber = max(gameData.runState?.turnNumber ?? 0, gameData.storyHistory.count)

        latestRun = RunSummary(
            playerName: gameData.playerName,
            hp: gameData.hp,
            maxHP: gameData.maxHP,
            turnNumber: max(1, turnNumber),
            lastPlayedText: formatter.string(from: lastPlayedDate)
        )
        hasRun = true
    }
}
