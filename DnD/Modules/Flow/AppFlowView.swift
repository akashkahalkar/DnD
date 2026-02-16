import SwiftUI

enum AppRoute: Hashable {
    case home
    case continueRun
    case narrative(startMode: NarrativeStartMode)
    case settings
    case about
}

enum NarrativeStartMode: String, Hashable {
    case newGame
    case continueRun
}

struct AppFlowView: View {
    @State private var path: [AppRoute] = []

    var body: some View {
        NavigationStack(path: $path) {
            HomeView(
                onStartNew: { path.append(.narrative(startMode: .newGame)) },
                onContinue: { path.append(.continueRun) },
                onSettings: { path.append(.settings) },
                onAbout: { path.append(.about) }
            )
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .home:
                    HomeView(
                        onStartNew: { path.append(.narrative(startMode: .newGame)) },
                        onContinue: { path.append(.continueRun) },
                        onSettings: { path.append(.settings) },
                        onAbout: { path.append(.about) }
                    )
                case .continueRun:
                    ContinueView(
                        onContinue: { path.append(.narrative(startMode: .continueRun)) },
                        onStartFresh: { path.append(.narrative(startMode: .newGame)) }
                    )
                case .narrative(let startMode):
                    NarrativeTestView(startMode: startMode)
                        .navigationBarTitleDisplayMode(.inline)
                case .settings:
                    PlaceholderScreen(
                        title: "Settings",
                        message: "Settings controls will appear here in the next module."
                    )
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
