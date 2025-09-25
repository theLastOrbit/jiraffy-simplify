//
//  AppDelegate.swift
//  JiraF MacOS
//
//  Created by MD RUBEL on 9/26/25.
//

import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide specific menu items
        ["File", "Edit", "View", "Window", "Help"]
            .compactMap { NSApp.mainMenu?.item(withTitle: $0) }
            .forEach { $0.isHidden = true }
    }
}
