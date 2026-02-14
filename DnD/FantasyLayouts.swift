import SwiftUI

// 1. Navigation Architecture
struct FantasyLayoutWrapper<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @State private var selectedTab: Int = 0
    
    // Detect iPad vs iPhone
    #if os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    #endif

    var body: some View {
        ZStack {
            FantasyBackground() // Base background
            
            #if os(iOS)
            if horizontalSizeClass == .regular {
                // IPAD / DESKTOP LAYOUT (Sidebar)
                HStack(spacing: 0) {
                    FantasySidebar(selectedTab: $selectedTab)
                    
                    ZStack {
                        // Main Content Area
                        content()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                // IPHONE LAYOUT (Bottom Tab Bar)
                ZStack {
                    content()
                        .padding(.bottom, 80) // Space for tab bar
                    
                    VStack {
                        Spacer()
                        FantasyTabBar(selectedTab: $selectedTab)
                    }
                }
            }
            #else
            // Fallback for other platforms (simplified)
             HStack(spacing: 0) {
                FantasySidebar(selectedTab: $selectedTab)
                content()
            }
            #endif
        }
    }
}

// 2. Sidebar (iPad)
struct FantasySidebar: View {
    @Binding var selectedTab: Int
    
    let tabs = [
        ("person.fill", "Hero"),
        ("bag.fill", "Inventory"),
        ("bolt.fill", "Spells"), // Or "Battle"
        ("person.3.fill", "Party"),
        ("gearshape.fill", "Settings")
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            // App Icon / Logo placeholder
            Circle()
                .fill(LinearGradient(colors: [.accentGold, .accentGoldDark], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 48, height: 48)
                .shadow(color: .accentGold.opacity(0.5), radius: 10)
                .overlay(Image(systemName: "dragon").foregroundColor(.black))
                .padding(.top, 40)
            
            Spacer()
            
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: { selectedTab = index }) {
                    VStack(spacing: 8) {
                        Image(systemName: tabs[index].0)
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == index ? .accentMagic : .textMuted)
                            .scaleEffect(selectedTab == index ? 1.1 : 1.0)
                            .shadow(color: selectedTab == index ? .accentMagic.opacity(0.8) : .clear, radius: 10)
                        
                        // Icon-only for sidebar is often cleaner, but labels can work if width allows.
                        // Spec says "Icons only" for Sidebar.
                    }
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(selectedTab == index ? Color.accentMagic.opacity(0.15) : Color.clear)
                    )
                    .overlay(
                         RoundedRectangle(cornerRadius: 16)
                            .stroke(selectedTab == index ? Color.accentMagic.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .frame(width: 80)
        .background(
            Color.bgSecondary.opacity(0.6)
                .background(.ultraThinMaterial)
        )
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color.white.opacity(0.1)),
            alignment: .trailing
        )
        .ignoresSafeArea()
    }
}

// 3. Tab Bar (iPhone)
struct FantasyTabBar: View {
    @Binding var selectedTab: Int
    
    // Tab Items
    let tabs = [
        ("person.fill", "Hero"),
        ("bag.fill", "Inventory"),
        ("flame.fill", "Battle"), // Center tab often special
        ("person.3.fill", "Party"),
        ("gearshape.fill", "Config")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        // Special center button styling (optional, often used for main action like Roll Dice or Battle)
                        if index == 2 {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(colors: [.accentGold, .accentGoldDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                                    )
                                    .frame(width: 56, height: 56)
                                    .shadow(color: .accentGold.opacity(0.6), radius: 15, y: 5)
                                
                                Image(systemName: tabs[index].0)
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.black)
                            }
                            .offset(y: -20) // Floating effect
                        } else {
                            Image(systemName: tabs[index].0)
                                .font(.system(size: 22))
                                .symbolVariant(selectedTab == index ? .fill : .none)
                            
                            Text(tabs[index].1)
                                .font(.fantasyCaption)
                                .scaleEffect(selectedTab == index ? 1.0 : 0.0) // Hide text when not selected if tight, or always show.
                                .opacity(selectedTab == index ? 1 : 0)
                                .frame(height: selectedTab == index ? nil : 0)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selectedTab == index ? .accentMagic : .textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 20) // Safe Area
        .padding(.top, 12)
        .background(
            // Glass Background for Tab Bar
            GlassShape()
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.3), radius: 10, y: -5)
                .overlay(
                    GlassShape()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
        )
        // .padding(.horizontal, 16) // Floating tab bar look
        // .padding(.bottom, 16)
    }
}

// Custom shape for safe area handling + floating look if needed
struct GlassShape: Shape {
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight], // Tab bar usually attached to bottom or floating
            cornerRadii: CGSize(width: 24, height: 24)
        )
        return Path(path.cgPath)
    }
}
