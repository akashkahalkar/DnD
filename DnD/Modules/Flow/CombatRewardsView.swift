import SwiftUI

struct CombatRewardsView: View {
    let xpGained: Int
    let rewards: [String]
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            FantasyBackground()

            VStack(spacing: 24) {
                Text("Victory Rewards")
                    .font(.fantasyTitleLarge)
                    .foregroundColor(.accentGold)

                FantasyPanel {
                    VStack(spacing: 12) {
                        Text("XP GAINED")
                            .font(.fantasyCaption)
                            .foregroundColor(.accentGold)
                            .tracking(2)

                        Text("+\(xpGained) XP")
                            .font(.fantasyTitle)
                            .foregroundColor(.accentNeon)

                        if rewards.isEmpty {
                            Text("No loot recovered this time.")
                                .font(.fantasyBody)
                                .foregroundColor(.textSecondary)
                        } else {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(rewards, id: \.self) { reward in
                                    Text("- \(reward)")
                                        .font(.fantasyBody)
                                        .foregroundColor(.textPrimary)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)

                FantasyPrimaryButton(title: "CONTINUE ADVENTURE") {
                    onContinue()
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 80)
        }
        .navigationTitle("Rewards")
        .navigationBarTitleDisplayMode(.inline)
    }
}
