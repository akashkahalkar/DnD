import SwiftUI

struct BattleScreen: View {
    var body: some View {
        ZStack {
            FantasyBackground()

            VStack(spacing: 24) {
                // Enemy Portrait Area
                VStack(spacing: 8) {
                    PortraitFrame(image: "enemy_dragon") // Fallback will handle if missing
                    Text("Ancient Dragon")
                        .font(.fantasyTitle)
                        .foregroundColor(.accentDanger)
                }
                .padding(.top, 40)

                Spacer()

                // Combat Log or Dialogue
                FantasyPanel {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("The dragon prepares its breath attack!")
                            .font(.fantasyBody)
                            .foregroundColor(.textPrimary)
                        Text("What will you do?")
                            .font(.fantasyBody)
                            .foregroundColor(.textMuted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // Action Cards
                HStack(spacing: 16) {
                    FantasyActionCard(icon: "flame.fill", title: "Fireball")
                    FantasyActionCard(icon: "bolt.fill", title: "Lighning Strike")
                }

                // Primary Interaction
                VStack(spacing: 12) {
                    FantasyMagicButton(title: "Cast Ultimate Spell") {
                        print("Ultimate spell cast!")
                    }
                    
                    HStack(spacing: 12) {
                        FantasyPrimaryButton(title: "Attack") {
                            print("attack")
                        }
                        
                        FantasySecondaryButton(title: "Defend") {
                            print("defend")
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

struct BattleScreen_Previews: PreviewProvider {
    static var previews: some View {
        BattleScreen()
    }
}
