import SwiftUI

// 3. Background System
struct FantasyBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.bgPrimary, .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

// 4. Panel Container
struct FantasyPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.bgSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.accentGold.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.6), radius: 8, x: 0, y: 6)
            )
    }
}

// 5. Button System
// Primary Button (Gold)
struct FantasyPrimaryButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.fantasyBody)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.accentGold)
                )
        }
        .scaleEffect(0.98)
    }
}

// Secondary Button
struct FantasySecondaryButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.fantasyBody)
                .foregroundColor(.accentGold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.accentGold, lineWidth: 1)
                )
        }
    }
}

// Danger Button
struct FantasyDangerButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.accentDanger)
                        .shadow(color: .accentDanger.opacity(0.7), radius: 8)
                )
        }
    }
}

// Magic Button (Animated Glow)
struct FantasyMagicButton: View {
    
    var title: String
    var action: () -> Void
    
    @State private var glow = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.fantasyBody)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.accentMagic)
                )
                .shadow(
                    color: Color.accentMagic.opacity(glow ? 0.9 : 0.3),
                    radius: glow ? 18 : 6
                )
                .scaleEffect(glow ? 1.02 : 1.0)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 1.4)
                .repeatForever(autoreverses: true)
            ) {
                glow.toggle()
            }
        }
    }
}

// 6. Action Card Component
struct FantasyActionCard: View {
    var icon: String
    var title: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 26))
                .foregroundColor(.accentMagic)

            Text(title)
                .font(.fantasyBody)
                .foregroundColor(.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.bgCard)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentGold.opacity(0.2))
                )
        )
    }
}

// 7. Portrait Frame
struct PortraitFrame: View {
    var image: String // Changed to String for easy asset reference or systemName fallback

    var body: some View {
        Group {
            if let uiImage = UIImage(named: image) {
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .padding(20)
                    .background(Color.bgCard)
            }
        }
        .scaledToFill()
        .frame(width: 120, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentGold, lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.7), radius: 8)
    }
}
