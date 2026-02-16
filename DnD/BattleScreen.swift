import SwiftUI

enum CombatOutcome {
    case victory
    case defeat
    case fled
}

struct BattleScreen: View {
    @Binding var player: Player
    @Binding var combatState: CombatState
    let onCombatEnd: (CombatOutcome) -> Void
    let onCombatUpdate: () -> Void

    @State private var logEntries: [String] = []
    @State private var isProcessing: Bool = false

    private let portraitService = PortraitService()
    @State private var enemyImage: UIImage?

    var body: some View {
        ZStack {
            FantasyBackground()

            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    PortraitFrame(image: enemyImage)
                        .ritualGlow(color: .accentDanger, radius: 20)

                    Text(combatState.enemy.name.uppercased())
                        .font(.fantasyTitle)
                        .foregroundColor(.accentDanger)
                }
                .padding(.top, 12)

                FantasyPanel {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Enemy")
                                .font(.fantasyCaption)
                                .foregroundColor(.accentGold)

                            Spacer()

                            Text("HP \(combatState.enemy.hp)/\(combatState.enemy.maxHP)")
                                .font(.fantasyCaption)
                                .foregroundColor(.accentNeon)
                        }

                        HStack {
                            Text("Player")
                                .font(.fantasyCaption)
                                .foregroundColor(.accentGold)

                            Spacer()

                            Text("HP \(player.hp)/\(player.maxHP)")
                                .font(.fantasyCaption)
                                .foregroundColor(.accentNeon)
                        }
                    }
                }
                .padding(.horizontal, 16)

                FantasyPanel {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Combat Log")
                            .font(.fantasyCaption)
                            .foregroundColor(.accentGold)
                            .tracking(2)

                        if logEntries.isEmpty {
                            Text("The air crackles. The battle begins.")
                                .font(.fantasyBody)
                                .foregroundColor(.textSecondary)
                        } else {
                            let recentEntries = Array(logEntries.suffix(4))
                            ForEach(recentEntries.indices, id: \.self) { index in
                                Text(recentEntries[index])
                                    .font(.fantasyBody)
                                    .foregroundColor(.textPrimary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 16)

                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        FantasyPrimaryButton(title: "ATTACK") {
                            performAttack()
                        }
                        .disabled(isProcessing)

                        FantasySecondaryButton(title: "DEFEND") {
                            performDefend()
                        }
                        .disabled(isProcessing)
                    }

                    HStack(spacing: 12) {
                        FantasySecondaryButton(title: "ABILITY") {
                            performAbility()
                        }
                        .disabled(isProcessing)

                        FantasySecondaryButton(title: "ITEM") {
                            performItem()
                        }
                        .disabled(isProcessing)
                    }

                    FantasyDangerButton(title: "FLEE") {
                        performFlee()
                    }
                    .disabled(isProcessing)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .task {
            await loadEnemyPortrait()
        }
        .onAppear {
            if logEntries.isEmpty {
                logEntries.append("A \(combatState.enemy.name) blocks your path.")
            }
        }
    }

    private func performAttack() {
        let action = CombatAction(
            name: "Strike",
            damageDice: .d8,
            bonus: player.abilityModifier(for: .strength)
        )
        performPlayerAction {
            var enemy = combatState.enemy
            let result = CombatEngine.calculatePlayerAttack(player: player, enemy: &enemy, action: action)
            combatState.enemy = enemy
            return result
        }
    }

    private func performAbility() {
        let action = CombatAction(
            name: "Arcane Burst",
            damageDice: .d10,
            bonus: max(player.abilityModifier(for: .intelligence), 1)
        )
        performPlayerAction {
            var enemy = combatState.enemy
            let result = CombatEngine.calculatePlayerAttack(player: player, enemy: &enemy, action: action)
            combatState.enemy = enemy
            return result
        }
    }

    private func performDefend() {
        performPlayerAction(enemyMultiplier: 0.5) {
            "You brace for impact, reducing incoming damage."
        }
    }

    private func performItem() {
        performPlayerAction {
            if let index = player.inventory.firstIndex(of: "Health Potion") {
                player.inventory.remove(at: index)
                let heal = min(12, player.maxHP - player.hp)
                player.hp += heal
                return heal > 0 ? "You drink a Health Potion and recover \(heal) HP." : "You drink a Health Potion but feel no stronger."
            } else {
                return "You fumble for a potion, but your satchel is empty."
            }
        }
    }

    private func performFlee() {
        guard !isProcessing else { return }
        isProcessing = true

        let roll = DiceRoller.roll(.d20, bonus: player.abilityModifier(for: .dexterity))
        if roll.total >= 12 {
            appendLog("You slip away into the shadows and escape the fight.")
            isProcessing = false
            onCombatEnd(.fled)
        } else {
            appendLog("You fail to escape. The foe closes in.")
            enemyTurn(multiplier: 1.0)
        }
    }

    private func performPlayerAction(enemyMultiplier: Double = 1.0, action: () -> String) {
        guard !isProcessing else { return }
        isProcessing = true

        let result = action()
        appendLog(result)
        combatState.lastActionResult = result

        if !combatState.enemy.isAlive {
            isProcessing = false
            appendLog("The \(combatState.enemy.name) collapses.")
            onCombatEnd(.victory)
            return
        }

        enemyTurn(multiplier: enemyMultiplier)
    }

    private func enemyTurn(multiplier: Double) {
        var mutablePlayer = player
        let (message, _) = CombatEngine.calculateEnemyAttack(
            enemy: combatState.enemy,
            player: &mutablePlayer,
            damageMultiplier: multiplier
        )
        player = mutablePlayer
        appendLog(message)

        combatState.playerTurn = true
        combatState.roundNumber += 1
        onCombatUpdate()

        if player.hp <= 0 {
            isProcessing = false
            onCombatEnd(.defeat)
            return
        }

        isProcessing = false
    }

    private func appendLog(_ entry: String) {
        logEntries.append(entry)
        onCombatUpdate()
    }

    private func loadEnemyPortrait() async {
        do {
            enemyImage = try await portraitService.fetchEnemyPortrait(
                type: combatState.enemy.type,
                traits: ["menacing", "shadowed", "battle-ready"]
            )
        } catch {
            print("Failed to generate enemy portrait: \(error)")
        }
    }
}

struct BattleScreen_Previews: PreviewProvider {
    static var previews: some View {
        BattleScreen(
            player: .constant(Player(name: "Aldric", hp: 40, maxHP: 45)),
            combatState: .constant(CombatState(
                enemy: Enemy(name: "Crypt Stalker", hp: 20, maxHP: 20, attackPower: 6, type: "Ghoul"),
                playerTurn: true,
                lastActionResult: nil,
                roundNumber: 1
            )),
            onCombatEnd: { _ in },
            onCombatUpdate: {}
        )
    }
}
