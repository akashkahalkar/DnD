import SwiftUI

struct BattleScreen: View {
    @State private var enemyImage: UIImage?
    private let portraitService = PortraitService()
    
    var body: some View {
        ZStack {
            FantasyBackground()

            VStack(spacing: 32) {
                // Enemy Portrait Area (Increased spacing and aura)
                VStack(spacing: 12) {
                    PortraitFrame(image: enemyImage)
                        .ritualGlow(color: .accentDanger, radius: 25)
                    Text("ANCIENT DRAGON")
                        .font(.fantasyTitleLarge)
                        .foregroundColor(.accentDanger)
                        .shadow(color: .black, radius: 2)
                }
                .padding(.top, 40)

                Spacer()

                // Combat Log or Dialogue (Glass UI Refined)
                FantasyPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("THE DRAGON PREPARES ITS BREATH ATTACK!")
                            .font(.fantasyTitle)
                            .foregroundColor(.accentDanger)
                        
                        Text("The air ripples with heat as the beast draws in a massive breath. Embers dance in its throat.")
                            .font(.fantasyBody)
                            .foregroundColor(.textPrimary)
                            .italic()

                        Text("What will you do, traveler?")
                            .font(.fantasyBodyBold)
                            .foregroundColor(.accentGold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 12)

                // Action Cards
                HStack(spacing: 20) {
                    FantasyActionCard(icon: "flame.fill", title: "FIREBALL", isSelected: true)
                    FantasyActionCard(icon: "bolt.fill", title: "LIGHTNING", isSelected: false)
                }
                .padding(.horizontal, 12)

                // Primary Interaction
                VStack(spacing: 16) {
                    FantasyMagicButton(title: "CAST ULTIMATE SPELL") {
                        print("Ultimate spell cast!")
                    }
                    .ritualGlow(color: .accentMagic, radius: 15)
                    
                    HStack(spacing: 16) {
                        FantasyPrimaryButton(title: "ATTACK") {
                            print("attack")
                        }
                        
                        FantasySecondaryButton(title: "DEFEND") {
                            print("defend")
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .padding(24)
        }
        .task {
            // Generate the dragon portrait on load
            do {
                enemyImage = try await portraitService.fetchEnemyPortrait(
                    type: "Ancient Red Dragon",
                    traits: ["glowing embers in throat", "massive crimson scales", "fierce intelligent eyes"]
                )
            } catch {
                print("Failed to generate dragon portrait: \(error)")
            }
        }
    }
}

struct BattleScreen_Previews: PreviewProvider {
    static var previews: some View {
        BattleScreen()
    }
}
