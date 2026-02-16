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
            AppFlowView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    ContentView()
}
