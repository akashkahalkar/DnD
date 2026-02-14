import SwiftUI

// 3. Background System
struct FantasyBackground: View {
    var body: some View {
        LinearGradient(
            colors: [.bgPrimary, .black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .etherealNoise()
        .ignoresSafeArea()
    }
}

// 4. Panel Container (Glass UI)
struct FantasyPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(24)
            .glassBackground(cornerRadius: 28)
            .overlay(RunicCorner().rotationEffect(.degrees(0)).padding(8), alignment: .topLeading)
            .overlay(RunicCorner().rotationEffect(.degrees(90)).padding(8), alignment: .topTrailing)
            .overlay(RunicCorner().rotationEffect(.degrees(270)).padding(8), alignment: .bottomLeading)
            .overlay(RunicCorner().rotationEffect(.degrees(180)).padding(8), alignment: .bottomTrailing)
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

// 6. Action Card Component (Glass UI)
struct FantasyActionCard: View {
    var icon: String
    var title: String
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(isSelected ? .white : .accentMagic)
                .shadow(color: isSelected ? .accentMagic : .clear, radius: 10)

            Text(title)
                .font(.fantasyBodyBold)
                .foregroundColor(.textPrimary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassBackground(cornerRadius: 20)
        .ritualGlow(color: isSelected ? .accentMagic : .clear, radius: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color.accentMagic : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}

// 7. Portrait Frame (Mythic)
struct PortraitFrame: View {
    var image: UIImage?

    var body: some View {
        Group {
            if let uiImage = image {
                Image(uiImage: uiImage)
                    .resizable()
            } else {
                ZStack {
                    Color.bgCard
                    ProgressView()
                        .tint(.accentGold)
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.accentGold.opacity(0.1))
                }
            }
        }
        .scaledToFill()
        .frame(width: 140, height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [.accentGold, .accentGoldDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
        )
        .shadow(color: .accentGold.opacity(0.2), radius: 15)
    }
}
