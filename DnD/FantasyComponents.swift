import SwiftUI

// 3. Background System
struct FantasyBackground: View {
    var body: some View {
        ZStack {
            Color.bgPrimary.ignoresSafeArea()
            
            // Subtle ambient gradients
            LinearGradient(
                colors: [.bgPrimary, .bgSecondary],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Arcane decorative glow (top left)
            RadialGradient(
                gradient: Gradient(colors: [.accentPurple.opacity(0.15), .clear]),
                center: .topLeading,
                startRadius: 0,
                endRadius: 600
            )
            .ignoresSafeArea()
            
            // Magic decorative glow (bottom right)
            RadialGradient(
                gradient: Gradient(colors: [.accentMagic.opacity(0.1), .clear]),
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 500
            )
            .ignoresSafeArea()
        }
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
            .padding(20) // Card padding: 16-20
            .glassBackground(cornerRadius: 20) // Base card radius
            // Removed RunicCorners for the cleaner NeoGlass look
    }
}

// 5. Button System
// Primary Button (Legendary Gold or Neon)
struct FantasyPrimaryButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.fantasyBodyBold)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 28) // Floating/Large button radius
                        .fill(
                            LinearGradient(
                                colors: [.accentGold, .accentGoldDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: .accentGoldDark.opacity(0.4), radius: 10, x: 0, y: 5)
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
                .font(.fantasyBodyBold)
                .foregroundColor(.textPrimary)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color.textSecondary.opacity(0.3), lineWidth: 1)
                        .background(Color.white.opacity(0.05).clipShape(RoundedRectangle(cornerRadius: 28)))
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
                .font(.fantasyBodyBold)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.accentDanger.opacity(0.8))
                        .shadow(color: .accentDanger.opacity(0.4), radius: 8)
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
                .font(.fantasyBodyBold)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(colors: [.accentNeon, .accentMagic], startPoint: .leading, endPoint: .trailing)
                        )
                )
                .shadow(
                    color: Color.accentNeon.opacity(glow ? 0.6 : 0.2),
                    radius: glow ? 20 : 8
                )
                .scaleEffect(glow ? 1.02 : 1.0)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 2.0)
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
                .font(.system(size: 24, weight: .bold)) // SF Symbols
                .foregroundColor(isSelected ? .accentNeon : .textSecondary)
                .shadow(color: isSelected ? .accentNeon.opacity(0.8) : .clear, radius: 10)

            Text(title)
                .font(.fantasyBody)
                .foregroundColor(isSelected ? .textPrimary : .textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .glassBackground(cornerRadius: 20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isSelected ? Color.accentNeon.opacity(0.6) : Color.clear, lineWidth: 1.5)
        )
        .shadow(color: isSelected ? .accentNeon.opacity(0.2) : .clear, radius: 15)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.textMuted.opacity(0.3))
                }
            }
        }
        .scaledToFill()
        .frame(width: 120, height: 120) // Slightly smaller/cleaner
        // Actually spec says "Hero card (character)". Let's enable rounded rectangle for "Card" feel.
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [.accentGold, .accentGoldDark.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10)
    }
}
