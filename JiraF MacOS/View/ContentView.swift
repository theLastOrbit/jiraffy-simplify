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
    @AppStorage("darkModeEnabled") private var darkMode = false
    
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
            
            VStack {
                Spacer()
                
                HStack {
                    Image(systemName: "sun.max")
                    Toggle("", isOn: $darkMode)
                        .toggleStyle(.switch)
                        .labelsHidden()
                    Image(systemName: "moon")
                    Spacer()
                }
            }
            .padding(32)
            
            LoadingOverlay(isVisible: root.isBusy)
        }
        .preferredColorScheme(darkMode ? .dark : .light)
    }
}

// Backward compatibility
typealias ContentView = RootView

#Preview { RootView() }
