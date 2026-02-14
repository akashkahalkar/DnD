//
//  ContentView.swift
//  DnD
//
//  Created by Akash on 12/02/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        FantasyLayoutWrapper {
            // This is where we would switch views based on the selected tab index passed down
            // or use a TabView logic inside LayoutWrapper.
            // For now, we display the main BattleScreen as the primary content.
            BattleScreen()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    ContentView()
}
