// Features/Auth/AuthView.swift
// MVVM Auth screen
import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var root: RootViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Authentication Required")
                .font(.title2)
            Text(root.statusMessage)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: {
                Task { await root.authenticate() }
            }) {
                Text("Authenticate")
                    .frame(minWidth: 140)
            }
            .keyboardShortcut(.defaultAction)
            .disabled(root.isBusy)
        }
        .padding(32)
    }
}

#Preview {
    AuthView()
        .environmentObject(RootViewModel())
}
