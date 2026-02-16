import SwiftUI

struct SettingsView: View {
    @AppStorage("settings.textSpeed") private var textSpeed: Double = 1.0
    @AppStorage("settings.animationsEnabled") private var animationsEnabled: Bool = true
    @AppStorage("settings.soundEnabled") private var soundEnabled: Bool = true

    let onResetRun: () -> Void

    var body: some View {
        ZStack {
            FantasyBackground()

            ScrollView {
                VStack(spacing: 24) {
                    FantasyPanel {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("TEXT & EFFECTS")
                                .font(.fantasyCaption)
                                .foregroundColor(.accentGold)
                                .tracking(2)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Text Speed")
                                    .font(.fantasyBodyBold)
                                    .foregroundColor(.textPrimary)

                                Slider(value: $textSpeed, in: 0.6...1.6, step: 0.1)
                                    .accentColor(.accentNeon)

                                Text("\(String(format: "%.1fx", textSpeed))")
                                    .font(.fantasyCaption)
                                    .foregroundColor(.textSecondary)
                            }

                            Toggle(isOn: $animationsEnabled) {
                                Text("Enable Animations")
                                    .font(.fantasyBody)
                                    .foregroundColor(.textPrimary)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .accentMagic))

                            Toggle(isOn: $soundEnabled) {
                                Text("Sound & Music")
                                    .font(.fantasyBody)
                                    .foregroundColor(.textPrimary)
                            }
                            .toggleStyle(SwitchToggleStyle(tint: .accentMagic))
                        }
                    }
                    .padding(.horizontal, 16)

                    FantasyPanel {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("DATA")
                                .font(.fantasyCaption)
                                .foregroundColor(.accentGold)
                                .tracking(2)

                            FantasyDangerButton(title: "RESET RUN") {
                                onResetRun()
                            }
                        }
                    }
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
