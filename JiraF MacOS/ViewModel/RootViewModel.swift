
import SwiftUI

@MainActor
final class RootViewModel: ObservableObject {
    enum Route { case auth, home }
    
    // Navigation
    @Published var route: Route = .auth
    
    // Shared state
    @Published var user: JiraUser?
    @Published var statusMessage: String = ""
    @Published var isBusy: Bool = false
    
    // Token
    private var session: AuthSession?
    
    private(set) var squads: [JiraSquad] = []
    
    init() {
        session = AuthManager.shared.loadSession()
        Task { await evaluateToken() }
        
        squads = [
            JiraSquad(name: "Alpha", value: "Squad Alpha"),
            JiraSquad(name: "Artisans", value: "Squad Artisans"),
            JiraSquad(name: "Lambda", value: "Squad Lambda"),
            JiraSquad(name: "Netcore", value: "Squad Netcore"),
            JiraSquad(name: "Omega", value: "Squad Omega"),
            JiraSquad(name: "Optimization", value: "Squad Optimization"),
            JiraSquad(name: "Sigma", value: "Squad Sigma")
        ]
    }
    
    // MARK: - Token Evaluation & Flow
    func evaluateToken() async {
        isBusy = true
        defer { isBusy = false }
        let state = AuthManager.shared.status(for: session)
        switch state {
        case .valid:
            statusMessage = "Token valid. Loading user…"
            await loadUserAndNavigate()
        case .needsRefresh:
            statusMessage = "Refreshing token…"
            await refreshTokenAndProceed()
        case .invalid:
            statusMessage = "Please authenticate."
            route = .auth
        }
    }
    
    private func refreshTokenAndProceed() async {
        guard let current = session else {
            route = .auth
            return
        }
        do {
            let refreshed = try await JiraAPIClient.shared.refresh(using: current)
            session = refreshed
            AuthManager.shared.saveSession(refreshed)
            await loadUserAndNavigate()
        } catch {
            statusMessage = "Refresh failed. Authenticate again."
            route = .auth
        }
    }
    
    func authenticate() async {
        isBusy = true
        statusMessage = "Authenticating…"
        defer { isBusy = false }
        do {
            let new = try await JiraAPIClient.shared.authenticate()
            session = new
            statusMessage = "Authenticated. Loading user…"
            await loadUserAndNavigate()
        } catch {
            statusMessage = "Authentication failed. Try again.\n" + String(describing: error)
            route = .auth
        }
    }
    
    private func loadUserAndNavigate() async {
        guard session != nil else {
            route = .auth
            return
        }
        do {
            let me = try await JiraAPIClient.shared.fetchMe()
            user = me
            statusMessage = "Welcome, \(me.displayName)"
            route = .home
        } catch {
            statusMessage = "Failed to load user profile."
            route = .auth
        }
    }
    
    func logout() {
        AuthManager.shared.clearSession()
        session = nil
        user = nil
        statusMessage = "Logged out."
        route = .auth
    }
}
