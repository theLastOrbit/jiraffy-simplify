
import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var root: RootViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            if let user = root.user {
                Text("Welcome, \(user.displayName) 👋")
                    .font(.largeTitle)
            } else {
                Text("Loading user…")
            }
            Text(root.statusMessage)
                .foregroundStyle(.secondary)
            HStack {
                Button("Reload User") { Task { await root.evaluateToken() } }
                    .disabled(root.isBusy)
                Button("Logout") {
                    root.logout()
                }
                .keyboardShortcut(.cancelAction)
            }
        }
        .padding(32)
    }
}

#Preview { HomeView().environmentObject(RootViewModel()) }
