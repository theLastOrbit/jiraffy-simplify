// Services/JiraAPIClient.swift
// Jira REST + OAuth helper using URLSession

import Foundation
import AppKit


final class JiraAPIClient {
    
    static let shared = JiraAPIClient()
    private init(session: URLSession = .shared) {
        self.urlSession = session
        self.auth = AuthManager.shared
    }
    
    private let urlSession: URLSession
    private let auth: AuthManager
    
    private let authBase = URL(string: "https://auth.atlassian.com")!
    private let apiBase = URL(string: "https://api.atlassian.com")!
    
    enum APIError: Error, CustomStringConvertible {
        case invalidURL
        case httpStatus(Int, String)
        case decoding(Error)
        case encoding(Error)
        case missingData
        case unknown(Error)
        
        var description: String {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .httpStatus(let code, let body): return "HTTP \(code): \(body)"
            case .decoding(let e): return "Decoding error: \(e)"
            case .encoding(let e): return "Encoding error: \(e)"
            case .missingData: return "Missing data"
            case .unknown(let e): return "Unknown error: \(e)"
            }
        }
    }
    
    // Generic request performer
    private func perform<T: Decodable>(_ request: URLRequest, decode type: T.Type) async throws -> T {
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw APIError.missingData
            }
            guard (200..<300).contains(http.statusCode) else {
                let body = String(data: data, encoding: .utf8) ?? "<no body>"
                throw APIError.httpStatus(http.statusCode, body)
            }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw APIError.decoding(error)
            }
        } catch let e as APIError {
            throw e
        } catch {
            throw APIError.unknown(error)
        }
    }
    
    func fetchMe() async throws -> JiraUser {
        guard let session = auth.loadSession() else {
            throw APIError.missingData
        }
        
        var url = apiBase
        url.append(path: "/me")
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        req.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        return try await perform(req, decode: JiraUser.self)
    }
    
    func refresh(using session: AuthSession) async throws -> AuthSession {
        
        var url = authBase
        url.append(path: "/oauth/token")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: String] = [
            "grant_type": "refresh_token",
            "client_id": auth.config.clientId,
            "client_secret": auth.config.clientSecret,
            "refresh_token": session.refreshToken
        ]
        
        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
        } catch {
            throw APIError.encoding(error)
        }
        
        let refreshed: TokenResponse = try await perform(req, decode: TokenResponse.self)
        let newAccess = refreshed.access_token
        let newRefresh = refreshed.refresh_token // Atlassian may or may not rotate
        let expiresAt = Date().addingTimeInterval(TimeInterval(refreshed.expires_in))
        
        return AuthSession(
            accessToken: newAccess,
            refreshToken: newRefresh,
            expiresAt: expiresAt,
            cloudId: session.cloudId
        )
    }
    
    func authenticate() async throws -> AuthSession {
        guard let url = URL(string: "http://localhost:3003/auth") else {
            throw APIError.invalidURL
        }
        
        await auth.start()
        sleep(3) // give the server a moment to start
        
        // open the URL in the default browser
#if os(macOS)
        NSWorkspace.shared.open(url)
#endif
        
        let session: AuthSession = try await withCheckedThrowingContinuation { [weak self] cont in
            guard let self else {
                cont.resume(throwing: APIError.missingData)
                return
            }
            auth.onAuthenticationComplete = { session in
                cont.resume(returning: session)
            }
        }
        
        Task {
            sleep(2)
            await auth.stop()
        }
        return session
    }
    
    func fetchTicketSummary(key: String) async throws -> String {
        guard let session = auth.loadSession() else {
            throw APIError.missingData
        }
        var url = apiBase
        url.append(path: "/ex/jira/\(session.cloudId)/rest/api/3/issue/\(key)")
        
        // Request only summary field to reduce payload
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "fields", value: "summary")]
        guard let finalURL = components?.url else {
            throw APIError.invalidURL
        }
        
        var req = URLRequest(url: finalURL)
        req.httpMethod = "GET"
        req.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        
        struct IssueResponse: Decodable {
            let key: String
            let fields: Fields
        }
        struct Fields: Decodable {
            let summary: String
        }
        
        let issue = try await perform(req, decode: IssueResponse.self)
        return issue.fields.summary
    }
    
    func createTicket(
        parentKey: String,
        summary: String,
        devHours: Double?,
        solutionHours: Double?,
        accountId: String,
        squadName: String
    ) async throws -> (key: String, summary: String) {
        guard let session = auth.loadSession() else {
            throw APIError.missingData
        }
        var base = apiBase
        base.append(path: "/ex/jira/\(session.cloudId)/rest/api/3/issue")
        
        let payload = JiraPayload(
            fields: .init(
                summary: summary,
                issuetype: .init(id: "10372"),
                project: .init(id: "10211"),
                parent: .init(key: parentKey),
                description: .init(content: [.init(content: [.init(text: summary)])]),
                assignee: .init(accountId: accountId),
                reporter: .init(accountId: accountId),
                customfield_10501: .init(value: squadName),
                customfield_10800: devHours,
                customfield_11405: solutionHours
            ),
            transition: .init(id: "941")
        )
        
        var req = URLRequest(url: base)
        req.httpMethod = "POST"
        req.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            req.httpBody = try JSONEncoder().encode(payload)
        } catch {
            throw APIError.encoding(error)
        }
        
        struct CreateIssueResponse: Decodable {
            let key: String
        }
        
        let response = try await perform(req, decode: CreateIssueResponse.self)
        return (key: response.key, summary: summary)
    }
}
