import SwiftUI

extension Color {
    // Base Surfaces
    static let bgPrimary = Color(hex: "#121212")     // app background
    static let bgSecondary = Color(hex: "#1C1C1E")   // panels
    static let bgCard = Color(hex: "#232326")        // cards

    // Accent Colors
    static let accentGold = Color(hex: "#E6BC5C")     // Celestial Gold
    static let accentGoldDark = Color(hex: "#99752D") // Ancient Gold
    static let accentMagic = Color(hex: "#00D2FF")    // Arcane Blue
    static let accentDanger = Color(hex: "#D32F2F")   // Crimson Blood
    static let accentSuccess = Color(hex: "#4F8A5B")

    // Text Colors
    static let textPrimary = Color(hex: "#F2F2F2")
    static let textSecondary = Color(hex: "#C7C7CC")
    static let textMuted = Color(hex: "#8E8E93")

    // Hex initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255,
                            (int >> 8) * 17,
                            (int >> 4 & 0xF) * 17,
                            (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255,
                            int >> 16,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24,
                            int >> 16 & 0xFF,
                            int >> 8 & 0xFF,
                            int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension Font {
    // Font Name Constants
    enum FantasyFont: String {
        case cinzel = "Cinzel"
        case cinzelDecorative = "CinzelDecorative"
        
        func name(weight: Weight) -> String {
            switch self {
            case .cinzel:
                switch weight {
                case .black: return "Cinzel-Black"
                case .bold: return "Cinzel-Bold"
                default: return "Cinzel-Regular"
                }
            case .cinzelDecorative:
                switch weight {
                case .black: return "CinzelDecorative-Black"
                case .bold: return "CinzelDecorative-Bold"
                default: return "CinzelDecorative-Regular"
                }
            }
        }
    }

    // Title Font (Fantasy)
    static let fantasyTitle = Font.custom(FantasyFont.cinzel.name(weight: .bold), size: 22)
    static let fantasyTitleLarge = Font.custom(FantasyFont.cinzel.name(weight: .black), size: 32)
    static let fantasyDecorative = Font.custom(FantasyFont.cinzelDecorative.name(weight: .bold), size: 24)
    
    // Body Font
    static let fantasyBody = Font.custom(FantasyFont.cinzel.name(weight: .regular), size: 16)
    static let fantasyBodyBold = Font.custom(FantasyFont.cinzel.name(weight: .bold), size: 16)
    
    // Helper for custom sizes
    static func fantasy(size: CGFloat, weight: Weight = .regular, decorative: Bool = false) -> Font {
        let family: FantasyFont = decorative ? .cinzelDecorative : .cinzel
        return Font.custom(family.name(weight: weight), size: size)
    }

    // Register custom fonts from the app bundle
    static func setupFonts() {
        let fontFiles = [
            "Cinzel-Black.ttf", "Cinzel-Bold.ttf", "Cinzel-Regular.ttf",
            "CinzelDecorative-Black.ttf", "CinzelDecorative-Bold.ttf", "CinzelDecorative-Regular.ttf"
        ]
        
        for file in fontFiles {
            if let url = Bundle.main.url(forResource: file, withExtension: nil) {
                var error: Unmanaged<CFError>?
                if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                    let errorDescription = error?.takeRetainedValue().localizedDescription ?? "Unknown error"
                    print("⚠️ Fantasy UI: Failed to register font (\(file)): \(errorDescription)")
                }
            }
        }
    }
}

// Glassmorphism Utility
extension View {
    func glassBackground(cornerRadius: CGFloat = 24) -> some View {
        self.background(
            ZStack {
                if #available(iOS 15.0, *) {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.bgSecondary.opacity(0.8))
                }
                
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [.accentGold.opacity(0.5), .clear, .accentGoldDark.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            }
        )
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 10)
    }
    
    func ritualGlow(color: Color = .accentMagic, radius: CGFloat = 15) -> some View {
        self.shadow(color: color.opacity(0.4), radius: radius)
            .shadow(color: color.opacity(0.2), radius: radius / 2)
    }
    
    func etherealNoise() -> some View {
        self.overlay(
            ZStack {
                Color.black.opacity(0.01)
                LinearGradient(
                    colors: [.clear, .white.opacity(0.03)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .blendMode(.overlay)
        )
    }
}

struct RunicCorner: View {
    var size: CGFloat = 12
    var color: Color = .accentGold
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: size))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: size, y: 0))
            
            // Add a small rune-like dot at the corner
            path.addEllipse(in: CGRect(x: -1, y: -1, width: 2, height: 2))
        }
        .stroke(color, lineWidth: 1.5)
        .frame(width: size, height: size)
    }
}
