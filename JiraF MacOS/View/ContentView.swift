//
//  ContentView.swift
//  JiraF MacOS
//
//  Created by MD RUBEL on 9/19/25.
//

import SwiftUI

// Root application view (formerly ContentView)
struct RootView: View {
    @StateObject private var root = RootViewModel()
    
    var body: some View {
        ZStack {
            switch root.route {
            case .auth:
                AuthView()
                    .environmentObject(root)
            case .home:
                HomeView()
                    .environmentObject(root)
            }
            LoadingOverlay(isVisible: root.isBusy)
        }
    }
}

// Backward compatibility
typealias ContentView = RootView

#Preview { RootView() }
