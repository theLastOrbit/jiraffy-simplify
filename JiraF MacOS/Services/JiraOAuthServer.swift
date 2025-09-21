//
//  OAuthServer.swift
//  JiraF MacOS
//
//  Created by MD RUBEL on 9/19/25.
//

import Foundation
import Hummingbird
import AsyncHTTPClient
import ServiceLifecycle
import Logging

final class JiraOAuthServer {
    
    private let config: JiraOAuthConfig
    private let httpClient: HTTPClient
    private var serviceGroup: ServiceGroup?
    
    private let scopes = [
        "read:jira-work",
        "write:jira-work",
        "read:me",
        "offline_access"
    ].joined(separator: " ")
    
    private let state = "secureRandomString123MdRubbbCodeSig"
    private let authSuccessHTML = """
<html>
<head>
    <title>Authentication Successful</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            display: flex;
            flex-direction: column;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
            background-color: #f5f5f5;
            text-align: center;
        }
        h1 {
            color: #28a745;
            font-size: 2.5em;
            margin-bottom: 0.5em;
        }
        p {
            color: #666;
            font-size: 1.2em;
            margin: 0.5em 0;
        }
    </style>
</head>
<body>
    <h1>Authentication Successful!</h1>
    <p>You can now close this window and return to the app.</p>
</body>
</html>
"""
    
    var onAuthenticationComplete: ((AuthSession) -> Void)?
    
    init(config: JiraOAuthConfig) {
        self.config = config
        self.httpClient = HTTPClient(eventLoopGroupProvider: .singleton)
    }
    
    deinit {
        try? httpClient.syncShutdown()
    }
    
    func start() async throws {
        let router = Router(context: BasicRequestContext.self)
        
        router.get("/auth") { [weak self] request, context in
            guard let self, let authUrl = buildAuthorizationURL() else {
                throw HTTPError(.internalServerError)
            }
            return Response(status: .seeOther, headers: [.location: authUrl])
        }
        
        router.get("/callback") { [weak self] request, context in
            guard let self else {
                throw HTTPError(.internalServerError)
            }
            return try await handleCallback(request: request)
        }
        
        let app = Application(
            router: router,
            configuration: .init(address: .hostname("localhost", port: config.port))
        )
        
        serviceGroup = ServiceGroup(
            configuration: ServiceGroupConfiguration(
                services: [app],
                logger: Logger(label: "jira-oauth")
            )
        )
        
        try await serviceGroup?.run()
    }
    
    func stop() async {
        await serviceGroup?.triggerGracefulShutdown()
        serviceGroup = nil
    }
    
    private func buildAuthorizationURL() -> String? {
        guard var components = URLComponents(string: "https://auth.atlassian.com/authorize") else {
            return nil
        }
        components.queryItems = [
            URLQueryItem(name: "audience", value: "api.atlassian.com"),
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "redirect_uri", value: config.redirectUri),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "prompt", value: "consent")
        ]
        return components.url?.absoluteString
    }
    
    private func handleCallback(request: Request) async throws -> Response {
        guard let code = request.uri.queryParameters["code"] else {
            let body = ResponseBody(byteBuffer: .init(string: "Error: No `code` provided"))
            return Response(status: .badRequest, body: body)
        }
        
        do {
            let tokenResponse = try await exchangeCodeForTokens(code: String(code))
            let cloudId = try await getCloudId(accessToken: tokenResponse.access_token)
            
            guard let cloudId else {
                let body = ResponseBody(byteBuffer: .init(string: "Could not retrieve cloud ID"))
                return Response(status: .internalServerError, body: body)
            }
            
            let expiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in))
            let session = AuthSession(
                accessToken: tokenResponse.access_token,
                refreshToken: tokenResponse.refresh_token,
                expiresAt: expiresAt,
                cloudId: cloudId
            )
            
            await MainActor.run { [weak self] in
                self?.onAuthenticationComplete?(session)
            }
            
            let body = ResponseBody(byteBuffer: .init(string: authSuccessHTML))
            return Response(status: .ok, body: body)
            
        } catch {
            let body = ResponseBody(byteBuffer: .init(string: "Error during OAuth flow"))
            return Response(status: .internalServerError, body: body)
        }
    }
    
    private func exchangeCodeForTokens(code: String) async throws -> TokenResponse {
        var request = HTTPClientRequest(url: "https://auth.atlassian.com/oauth/token")
        request.method = .POST
        request.headers.add(name: "Content-Type", value: "application/json")
        
        let requestBody = [
            "grant_type": "authorization_code",
            "client_id": config.clientId,
            "client_secret": config.clientSecret,
            "code": code,
            "redirect_uri": config.redirectUri
        ]
        
        let bodyData = try JSONSerialization.data(withJSONObject: requestBody)
        request.body = .bytes(bodyData)
        
        let response = try await httpClient.execute(request, timeout: .seconds(60))
        let responseData = try await response.body.collect(upTo: .max)
        return try JSONDecoder().decode(TokenResponse.self, from: Data(responseData.readableBytesView))
    }
    
    private func getCloudId(accessToken: String) async throws -> String? {
        var request = HTTPClientRequest(url: "https://api.atlassian.com/oauth/token/accessible-resources")
        request.method = .GET
        request.headers.add(name: "Authorization", value: "Bearer \(accessToken)")
        
        let response = try await httpClient.execute(request, timeout: .seconds(60))
        let responseData = try await response.body.collect(upTo: .max)
        let cloudResources = try JSONDecoder().decode(
            [CloudResource].self,
            from: Data(responseData.readableBytesView)
        )
        
        return cloudResources.first?.id
    }
}

struct TokenResponse: Codable {
    let access_token: String
    let refresh_token: String
    let expires_in: Double
}

fileprivate struct CloudResource: Codable {
    let id: String
}
