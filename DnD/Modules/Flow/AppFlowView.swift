import SwiftUI

enum AppRoute: Hashable {
    case characterCreation
    case continueRun
    case narrative(startMode: NarrativeStartMode)
    case about
}

enum NarrativeStartMode: String, Hashable {
    case newGame
    case continueRun
}

struct AppFlowView: View {
    @State private var path: [AppRoute] = []
    @State private var pendingNewPlayer: Player?
    @State private var selectedTab: RootTab = .home

    var body: some View {
        NavigationStack(path: $path) {
            TabView(selection: $selectedTab) {
                HomeView(
                    onStartNew: { path.append(.characterCreation) },
                    onContinue: { path.append(.continueRun) },
                    onSettings: { selectedTab = .settings },
                    onAbout: { path.append(.about) }
                )
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(RootTab.home)

                CampaignsView()
                    .tabItem {
                        Label("Campaigns", systemImage: "square.grid.3x3.fill")
                    }
                    .tag(RootTab.campaigns)

                if #available(iOS 26.0, *) {
                    PlayerProgressView()
                        .tabItem {
                            Label("Player", systemImage: "person.fill")
                        }
                        .tag(RootTab.player)
                } else {
                        // Fallback on earlier versions
                }

                SettingsView(onResetRun: {
                    DataService.shared.clearAllSaves()
                })
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(RootTab.settings)
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .characterCreation:
                    CharacterCreationView(
                        onComplete: { newPlayer in
                            pendingNewPlayer = newPlayer
                            path.append(.narrative(startMode: .newGame))
                        },
                        onCancel: { path.removeLast() }
                    )
                case .continueRun:
                    ContinueView(
                        onContinue: { path.append(.narrative(startMode: .continueRun)) },
                        onStartFresh: { path.append(.characterCreation) }
                    )
                case .narrative(let startMode):
                    NarrativeTestView(startMode: startMode, playerOverride: pendingNewPlayer)
                        .navigationBarTitleDisplayMode(.inline)
                case .about:
                    PlaceholderScreen(
                        title: "About",
                        message: "Build 0.1 • Text-based DnD vertical slice."
                    )
                }
            }
        }
    }
}

private enum RootTab: Hashable {
    case home
    case campaigns
    case player
    case settings
}

private struct PlaceholderScreen: View {
    let title: String
    let message: String

    var body: some View {
        ZStack {
            FantasyBackground()
            VStack(spacing: 24) {
                Text(title)
                    .font(.fantasyTitleLarge)
                    .foregroundColor(.accentGold)

                FantasyPanel {
                    Text(message)
                        .font(.fantasyBody)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)
            }
            .padding(.top, 80)
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
