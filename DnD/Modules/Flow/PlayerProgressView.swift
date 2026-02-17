import SwiftUI
import Combine

@available(iOS 26.0, *)
struct PlayerProgressView: View {
    @StateObject private var viewModel = PlayerProgressViewModel()

    var body: some View {
        ZStack {
            FantasyBackground()

            ScrollView {
                VStack(spacing: 20) {
                    Text("Hero Ledger")
                        .font(.fantasyTitleLarge)
                        .foregroundColor(.accentGold)
                        .padding(.top, 50)

                    if let summary = viewModel.summary {
                        FantasyPanel {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(summary.name)
                                    .font(.fantasyBodyBold)
                                    .foregroundColor(.textPrimary)

                                Text("Campaign \(summary.activeCampaign), Quest \(summary.activeQuest), Act \(summary.act)")
                                    .font(.fantasyCaption)
                                    .foregroundColor(.textSecondary)

                                Text("Level \(summary.level)  •  XP \(summary.xp)  •  Unspent \(summary.unspentPoints)")
                                    .font(.fantasyBody)
                                    .foregroundColor(.accentNeon)

                                Text("Threat Meter: \(summary.threatLevel)/10")
                                    .font(.fantasyCaption)
                                    .foregroundColor(.accentDanger)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.horizontal, 16)

                        FantasyPanel {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Ability Scores")
                                    .font(.fantasyCaption)
                                    .foregroundColor(.accentGold)
                                    .tracking(2)

                                ForEach(summary.abilityRows, id: \.label) { row in
                                    HStack {
                                        Text(row.label)
                                            .font(.fantasyBody)
                                            .foregroundColor(.textPrimary)
                                        Spacer()
                                        Text("\(row.score) (\(row.modifier >= 0 ? "+" : "")\(row.modifier))")
                                            .font(.fantasyCaption)
                                            .foregroundColor(.textSecondary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    } else {
                        FantasyPanel {
                            Text("No hero profile found. Start a run first.")
                                .font(.fantasyBody)
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            Task { await viewModel.refresh() }
        }
    }
}

@available(iOS 26.0, *)
@MainActor
final class PlayerProgressViewModel: ObservableObject {
    struct AbilityRow {
        let label: String
        let score: Int
        let modifier: Int
    }

    struct Summary {
        let name: String
        let activeCampaign: Int
        let activeQuest: Int
        let act: Int
        let xp: Int
        let level: Int
        let unspentPoints: Int
        let threatLevel: Int
        let abilityRows: [AbilityRow]
    }

    @Published var summary: Summary?

    private let dataService = DataService.shared
    private let campaignService = CampaignService.shared

    func refresh() async {
        guard let gameData = dataService.fetchLatestGame() else {
            summary = nil
            return
        }

        await campaignService.ensureCampaignData(for: gameData)

        let player = dataService.player(from: gameData)
        let progression = dataService.loadProgressionState(from: gameData) ?? ProgressionState(xp: 0, level: 1, unspentPoints: 0, recentRewards: [])
        let runtime = campaignService.runtimeState(for: gameData)

        summary = Summary(
            name: player.name,
            activeCampaign: runtime.activeCampaignIndex,
            activeQuest: runtime.activeQuestIndex,
            act: act(for: runtime.activeQuestIndex),
            xp: progression.xp,
            level: progression.level,
            unspentPoints: progression.unspentPoints,
            threatLevel: runtime.threatLevel,
            abilityRows: Ability.allCases.map {
                AbilityRow(
                    label: $0.rawValue.uppercased(),
                    score: player.abilityScore(for: $0),
                    modifier: player.abilityModifier(for: $0)
                )
            }
        )
    }

    private func act(for quest: Int) -> Int {
        switch quest {
        case 1...3:
            return 1
        case 4...6:
            return 2
        default:
            return 3
        }
    }
}
