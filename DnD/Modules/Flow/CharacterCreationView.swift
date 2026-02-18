import SwiftUI

struct CharacterCreationView: View {
    let onComplete: (Player) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var selectedArchetype: String = "Warden"
    @State private var abilityScores: [Ability: Int] = Ability.defaultScores
    @State private var remainingPoints: Int = Ability.defaultUnspentPoints

    private let archetypes = [
        "Warden",
        "Shadow",
        "Sage",
        "Vanguard"
    ]

    var body: some View {
        ZStack {
            FantasyBackground()

            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text("Forge Your Hero")
                            .font(.fantasyTitleLarge)
                            .foregroundColor(.accentGold)

                        Text("Name your adventurer and distribute ability points.")
                            .font(.fantasyCaption)
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 60)

                    FantasyPanel {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Hero Identity")
                                .font(.fantasyCaption)
                                .foregroundColor(.accentGold)
                                .tracking(2)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("NAME")
                                    .font(.fantasyCaption)
                                    .foregroundColor(.textSecondary)

                                TextField("Aldric the Brave", text: $name)
                                    .font(.fantasyBody)
                                    .foregroundColor(.textPrimary)
                                    .padding(12)
                                    .background(Color.white.opacity(0.08))
                                    .cornerRadius(12)
                            }

                            HStack {
                                Text("ARCHETYPE")
                                    .font(.fantasyCaption)
                                    .foregroundColor(.textSecondary)
                                Spacer()
                                Picker("ARCHETYPE", selection: $selectedArchetype) {
                                    ForEach(archetypes, id: \.self) { archtype in
                                        Text(archtype).tag(archtype)
                                            .background(                                                   RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedArchetype == archtype ? Color.accentGold : Color.white.opacity(0.08))
                                            )
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    FantasyPanel {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("ABILITY POINTS")
                                    .font(.fantasyCaption)
                                    .foregroundColor(.accentGold)
                                    .tracking(2)
                                Spacer()
                                Text("Remaining: \(remainingPoints)")
                                    .font(.fantasyBodyBold)
                                    .foregroundColor(remainingPoints > 0 ? .accentNeon : .textSecondary)
                            }

                            VStack(spacing: 12) {
                                ForEach(Ability.allCases, id: \.self) { ability in
                                    AbilityRow(
                                        ability: ability,
                                        score: abilityScores[ability, default: Ability.baselineScore],
                                        canDecrease: abilityScores[ability, default: Ability.baselineScore] > Ability.baselineScore,
                                        canIncrease: remainingPoints > 0,
                                        onDecrease: { adjustAbility(ability, delta: -1) },
                                        onIncrease: { adjustAbility(ability, delta: 1) }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    VStack(spacing: 12) {
                        FantasyPrimaryButton(title: "BEGIN ADVENTURE") {
                            onComplete(buildPlayer())
                        }

                        FantasySecondaryButton(title: "BACK") {
                            onCancel()
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Character")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if #available(iOS 26.0, *) {
                await LLMClient.shared.prewarmStorySession(
                    promptPrefix: """
                    Generate concise dark-fantasy campaign seed titles.
                    Return short titles only.
                    """
                )
            }
        }
    }

    private func adjustAbility(_ ability: Ability, delta: Int) {
        let current = abilityScores[ability, default: Ability.baselineScore]
        let next = current + delta
        guard next >= Ability.baselineScore else { return }
        guard delta <= remainingPoints else { return }
        abilityScores[ability] = next
        remainingPoints -= delta
    }

    private func buildPlayer() -> Player {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? "Wanderer" : trimmed
        return Player(
            name: finalName,
            hp: Player.defaultMaxHP,
            maxHP: Player.defaultMaxHP,
            archetype: selectedArchetype,
            abilityScores: abilityScores,
            unspentAbilityPoints: remainingPoints,
            inventory: ["Longsword", "Health Potion", "Torch"]
        )
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
        HStack(spacing: 8) {
            Text(ability.rawValue.uppercased())
                .font(.fantasyBodyBold)
                .foregroundColor(.textPrimary)
                .frame(alignment: .leading)
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
