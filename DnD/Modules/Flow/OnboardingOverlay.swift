import SwiftUI

struct OnboardingOverlay: View {
    @Binding var isVisible: Bool

    var body: some View {
        if isVisible {
            ZStack {
                Color.black.opacity(0.6).ignoresSafeArea()

                FantasyPanel {
                    VStack(spacing: 16) {
                        Text("How to Play")
                            .font(.fantasyTitle)
                            .foregroundColor(.accentGold)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("- Choose story options to shape the quest.")
                            Text("- Dice rolls resolve risky actions.")
                            Text("- Combat uses tactical actions each turn.")
                            Text("- Winning battles earns XP and loot.")
                            Text("- Quest outcomes lead to victory or failure.")
                        }
                        .font(.fantasyBody)
                        .foregroundColor(.textPrimary)

                        FantasyPrimaryButton(title: "BEGIN") {
                            UserDefaults.standard.set(true, forKey: "onboarding.dismissed")
                            isVisible = false
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
            .transition(.opacity)
        }
    }
}
