//
//  JiraF_MacOSApp.swift
//  JiraF MacOS
//
//  Created by MD RUBEL on 9/19/25.
//

import SwiftUI

@main
struct JiraF_MacOSApp: App {
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 1280, height: 720)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
        // Override default menus
        .commands {
            CommandGroup(replacing: .appVisibility) { }
            CommandGroup(replacing: .appInfo) { }
            CommandGroup(replacing: .systemServices) { }
        }
    }
}
