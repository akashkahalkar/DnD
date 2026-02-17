import SwiftUI

struct QuestFailedView: View {
    let summary: String
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            FantasyBackground()

            VStack(spacing: 24) {
                Text("Quest Failed")
                    .font(.fantasyTitleLarge)
                    .foregroundColor(.accentDanger)

                FantasyPanel {
                    Text(summary)
                        .font(.fantasyBody)
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 16)

                FantasyPrimaryButton(title: "START NEW QUEST") {
                    onContinue()
                }
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 80)
        }
        .navigationTitle("Quest Failed")
        .navigationBarTitleDisplayMode(.inline)
    }
}
