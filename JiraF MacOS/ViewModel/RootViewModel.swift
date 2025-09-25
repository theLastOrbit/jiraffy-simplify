import Foundation
#if canImport(AppKit)
import AppKit
#endif

@MainActor
final class RootViewModel: ObservableObject {
    enum Route { case auth, home }
    
    // Navigation
    @Published private(set) var route: Route = .auth
    
    // Shared state
    @Published private(set) var user: JiraUser?
    @Published private(set) var statusMessage: String = ""
    @Published var isBusy: Bool = false
    @Published var rows: [InputFieldRow] = [InputFieldRow()]
    
    @Published private(set) var hasResults: Bool = false
    @Published private(set) var tickets: [JiraTicket] = []
    
    // Token
    private var session: AuthSession?
    private let api = JiraAPIClient.shared
    
    private(set) var squads: [JiraSquad] = []
    private(set) var projectKeyPrefix: String = ""
    private var browseBaseURL = ""
    
    var parentTicketName: String = ""
    
    init() {
        session = AuthManager.shared.loadSession()
        Task { await evaluateToken() }
        
        squads = [
            JiraSquad(name: "Alpha", value: "Squad Alpha"),
            JiraSquad(name: "Artisans", value: "Squad Artisans"),
            JiraSquad(name: "Lambda", value: "Squad Lambda"),
            JiraSquad(name: "Netcore", value: "Squad Netcore"),
            JiraSquad(name: "Omega", value: "Squad Omega"),
            JiraSquad(name: "Optimization", value: "Optimization"),
            JiraSquad(name: "Sigma", value: "Squad Sigma"),
            JiraSquad(name: "Squad Eight", value: "Squad Eight")
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
            let refreshed = try await api.refresh(using: current)
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
            let new = try await api.authenticate()
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
            let me = try await api.fetchMe()
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
    
    func getTicket(key: String) async throws -> Bool {
        isBusy = true
        do {
            let ticketName = try await api.fetchTicketSummary(key: key)
            parentTicketName = ticketName
            isBusy = false
            return !ticketName.isEmpty
            
        } catch {
            parentTicketName = ""
            isBusy = false
            throw error
        }
    }
    
    func createSubtask(parentKey: String, squadName: String?) async {
        guard let userId = user?.id, let squadName else {
            return
        }
        
        isBusy = true
        hasResults = true
        
        for row in rows {
            guard row.isValid else {
                continue
            }
            
            do {
                let result = try await api.createTicket(
                    parentKey: parentKey,
                    summary: row.title,
                    devHours: Double(row.devHours),
                    solutionHours: Double(row.solutionHours),
                    accountId: userId,
                    squadName: squadName
                )
                
                let ticket = JiraTicket(key: result.key, summary: result.summary)
                tickets.append(ticket)
                
            } catch {
                print("Failed to create ticket for row \(row.title): \(error)")
            }
        }
        
        isBusy = false
    }
    
    func reset() {
        isBusy = true
        tickets.removeAll()
        rows.removeAll()
        rows.append(InputFieldRow())
        hasResults = false
        isBusy = false
    }
    
    // MARK: - Ticket Browsing
    func openTicket(_ key: String) {
        let full = browseBaseURL + key
        guard let url = URL(string: full) else { return }
#if os(macOS)
        NSWorkspace.shared.open(url)
#endif
    }
}
