import SwiftUI

struct ContinueView: View {
    let onContinue: () -> Void
    let onStartFresh: () -> Void

    @StateObject private var viewModel = RunSelectionViewModel()

    var body: some View {
        ZStack {
            FantasyBackground()

            VStack(spacing: 24) {
                Text("Continue Run")
                    .font(.fantasyTitleLarge)
                    .foregroundColor(.accentGold)

                if let summary = viewModel.latestRun {
                    FantasyPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(summary.playerName)
                                .font(.fantasyBodyBold)
                                .foregroundColor(.textPrimary)

                            Text("HP: \(summary.hp)/\(summary.maxHP)")
                                .font(.fantasyCaption)
                                .foregroundColor(.accentNeon)

                            Text("Turn \(summary.turnNumber)")
                                .font(.fantasyCaption)
                                .foregroundColor(.textSecondary)

                            Text("Last played \(summary.lastPlayedText)")
                                .font(.fantasyCaption)
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 16)

                    FantasyPrimaryButton(title: "RESUME ADVENTURE") {
                        onContinue()
                    }
                    .padding(.horizontal, 16)

                    FantasySecondaryButton(title: "START FRESH RUN") {
                        onStartFresh()
                    }
                    .padding(.horizontal, 16)
                } else {
                    FantasyPanel {
                        Text("No saved run found. Start a new adventure.")
                            .font(.fantasyBody)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 16)

                    FantasyPrimaryButton(title: "START NEW RUN") {
                        onStartFresh()
                    }
                    .padding(.horizontal, 16)
                }

                Spacer()
            }
            .padding(.top, 80)
        }
        .onAppear {
            viewModel.refresh()
        }
        .navigationTitle("Continue")
        .navigationBarTitleDisplayMode(.inline)
    }
}
