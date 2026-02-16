import SwiftUI

struct LevelUpView: View {
    @Binding var player: Player
    @Binding var progression: ProgressionState
    let onConfirm: () -> Void

    @State private var pendingScores: [Ability: Int] = [:]
    @State private var pendingPoints: Int = 0

    var body: some View {
        ZStack {
            FantasyBackground()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Level Up")
                            .font(.fantasyTitleLarge)
                            .foregroundColor(.accentGold)

                        Text("Level \(progression.level)")
                            .font(.fantasyBodyBold)
                            .foregroundColor(.accentNeon)
                    }
                    .padding(.top, 60)

                    FantasyPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Unspent Points: \(pendingPoints)")
                                .font(.fantasyBodyBold)
                                .foregroundColor(pendingPoints > 0 ? .accentNeon : .textSecondary)

                            VStack(spacing: 12) {
                                ForEach(Ability.allCases, id: \.self) { ability in
                                    let score = pendingScores[ability, default: player.abilityScore(for: ability)]
                                    AbilityRow(
                                        ability: ability,
                                        score: score,
                                        canDecrease: score > player.abilityScore(for: ability),
                                        canIncrease: pendingPoints > 0,
                                        onDecrease: { adjust(ability, delta: -1) },
                                        onIncrease: { adjust(ability, delta: 1) }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    FantasyPrimaryButton(title: "CONFIRM") {
                        applyChanges()
                        onConfirm()
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            pendingScores = player.abilityScores
            pendingPoints = progression.unspentPoints
        }
        .navigationTitle("Level Up")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func adjust(_ ability: Ability, delta: Int) {
        let current = pendingScores[ability, default: player.abilityScore(for: ability)]
        let next = current + delta
        guard next >= player.abilityScore(for: ability) else { return }
        guard delta <= pendingPoints else { return }
        pendingScores[ability] = next
        pendingPoints -= delta
    }

    private func applyChanges() {
        player.abilityScores = pendingScores
        progression.unspentPoints = pendingPoints
    }
}

private struct AbilityRow: View {
    let ability: Ability
    let score: Int
    let canDecrease: Bool
    let canIncrease: Bool
    let onDecrease: () -> Void
    let onIncrease: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(ability.rawValue.uppercased())
                .font(.fantasyBodyBold)
                .foregroundColor(.textPrimary)
                .frame(width: 100, alignment: .leading)

            Spacer()

            Button(action: onDecrease) {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(canDecrease ? .accentGold : .textMuted)
            }
            .disabled(!canDecrease)

            Text("\(score)")
                .font(.fantasyBodyBold)
                .foregroundColor(.textPrimary)
                .frame(width: 32)

            Button(action: onIncrease) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(canIncrease ? .accentNeon : .textMuted)
            }
            .disabled(!canIncrease)
        }
    }
}
