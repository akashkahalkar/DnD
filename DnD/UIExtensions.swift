import SwiftUI

extension Color {
    // Base Surfaces
    static let bgPrimary = Color(hex: "#0F1117")     // Primary Background
    static let bgSecondary = Color(hex: "#151821")   // Secondary Background
    static let bgCard = Color(hex: "#1C2130")        // Elevated Surface / Card
    static let glassTint = Color(red: 30/255, green: 35/255, blue: 48/255, opacity: 0.55)

    // Accent Colors
    static let accentGold = Color(hex: "#FFB84D")     // Legendary Gold
    static let accentGoldDark = Color(hex: "#FF7A00") // For gradients
    static let accentMagic = Color(hex: "#5CA9FF")    // Magic Blue
    static let accentPurple = Color(hex: "#7A6CFF")   // Arcane Purple
    static let accentNeon = Color(hex: "#5CFF9D")     // Neon Primary
    static let accentDanger = Color(hex: "#FF5C7A")   // Danger Red
    static let accentSuccess = Color(hex: "#4F8A5B")  // Keep existing green as fallback, or use Neon

    // Text Colors
    static let textPrimary = Color(hex: "#F2F4F8")
    static let textSecondary = Color(hex: "#B7BDCC")
    static let textMuted = Color(hex: "#7E8599")
    static let textDisabled = Color(hex: "#50576B")

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

    // Title Font (Fantasy) - Keep Cinzel for headings
    static let fantasyTitle = Font.custom(FantasyFont.cinzel.name(weight: .bold), size: 28) // Hero
    static let fantasyTitleMedium = Font.custom(FantasyFont.cinzel.name(weight: .bold), size: 22)
    static let fantasyTitleLarge = Font.custom(FantasyFont.cinzel.name(weight: .black), size: 32)
    static let fantasyDecorative = Font.custom(FantasyFont.cinzelDecorative.name(weight: .bold), size: 24)
    
    // Body Font - SF Pro Rounded (System)
    static let fantasyBody = Font.system(size: 15, weight: .regular, design: .rounded)
    static let fantasyBodyBold = Font.system(size: 15, weight: .semibold, design: .rounded)
    static let fantasyCaption = Font.system(size: 13, weight: .regular, design: .rounded)
    static let fantasyStat = Font.system(size: 22, weight: .bold, design: .monospaced)
    
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
    func glassBackground(cornerRadius: CGFloat = 20) -> some View {
        self.background(
            ZStack {
                // Blur layer
                if #available(iOS 15.0, *) {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(Color.bgSecondary.opacity(0.85))
                }
                
                // Tint layer (Dark overlay 20-30%)
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.black.opacity(0.25))
                
                // Border: Subtle gradient 1px
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .white.opacity(0.05),
                                .white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        // Shadow: y:8 blur:30 opacity:0.25 -> radius: 30, y: 10 roughly
        .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 10)
    }
    
    func ritualGlow(color: Color = .accentMagic, radius: CGFloat = 20) -> some View {
        self.shadow(color: color.opacity(0.4), radius: radius)
            .shadow(color: color.opacity(0.2), radius: radius / 2)
            .overlay(
                // Screen/Add blend mode simulation in SwiftUI can be tricky,
                // often just an overlay with opacity works for simple glows
                Color.clear
            )
    }
    
    func etherealNoise() -> some View {
        self.overlay(
            ZStack {
                Color.bgPrimary.opacity(0.9) // Base darkened
                // Add noise image if available, otherwise just subtle gradient
                LinearGradient(
                    colors: [.clear, .accentPurple.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .blendMode(.overlay)
            .allowsHitTesting(false)
        )
    }
}

struct RunicCorner: View {
    var size: CGFloat = 12
    var color: Color = .accentGold
    
    var body: some View {
        // Runic corners are less emphasized in the new clean glass design,
        // but we can keep them subtle or remove them.
        // Spec: "Visual-first, text-light... Glass + depth + glow"
        // It doesn't explicitly forbid runic corners, but "Clean" usually suggests less ornamentation.
        // We will make them very subtle or keep as is for "Fantasy" flavor.
        Path { path in
            path.move(to: CGPoint(x: 0, y: size))
            path.addLine(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: size, y: 0))
        }
        .stroke(color.opacity(0.6), lineWidth: 1.5)
        .frame(width: size, height: size)
    }
}
