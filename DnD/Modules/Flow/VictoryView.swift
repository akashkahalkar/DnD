import SwiftUI

struct VictoryView: View {
    let summary: String
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            FantasyBackground()

            VStack(spacing: 24) {
                Text("Victory")
                    .font(.fantasyTitleLarge)
                    .foregroundColor(.accentGold)

                FantasyPanel {
                    Text(summary)
                        .font(.fantasyBody)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
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
        .navigationTitle("Victory")
        .navigationBarTitleDisplayMode(.inline)
    }
}
