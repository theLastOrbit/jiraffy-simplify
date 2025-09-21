// AuthManager.swift
// Handles token persistence and validation
import Foundation

final class AuthManager {
    
    static let shared = AuthManager()
    
    private init() {
    }
    
    private let storageKey = "jira_auth_token_v1"
    private var serverTask: Task<Void, Error>?
    private var server: JiraOAuthServer?
    private(set) var config: JiraOAuthConfig
    
    var onAuthenticationComplete: ((AuthSession) -> Void)?
    
    func loadSession() -> AuthSession? {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return nil
        }
        return try? JSONDecoder().decode(AuthSession.self, from: data)
    }
    
    func saveSession(_ session: AuthSession) {
        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
    
    func clearSession() {
        UserDefaults.standard.removeObject(forKey: storageKey)
    }
    
    enum SessionStatus {
        case valid
        case needsRefresh
        case invalid
    }
    
    func status(for session: AuthSession?) -> SessionStatus {
        guard let session, !session.isExpired else {
            return .invalid
        }
        if session.isValidForAtLeastTenMinutes {
            return .valid
        }
        return .needsRefresh
    }
    
    func start() async {
        guard server == nil else {
            // Server is already running
            return
        }
        
        server = JiraOAuthServer(config: config)
        
        serverTask?.cancel()
        serverTask = Task.detached(priority: .userInitiated) { [weak self] in
            do {
                try await self?.server?.start()
            } catch {
                print("==> Failed to start OAuth server: \(error)")
            }
        }
        
        server?.onAuthenticationComplete = { [weak self] session in
            self?.saveSession(session)
            self?.onAuthenticationComplete?(session)
        }
    }
    
    func stop() async {
        await server?.stop()
        serverTask?.cancel()
        serverTask = nil
        server = nil
    }
}
