//
//  JiraOAuthConfig.swift
//  JiraF MacOS
//
//  Created by MD RUBEL on 9/20/25.
//

import Foundation

struct JiraOAuthConfig {
    let clientId: String
    let clientSecret: String
    let redirectUri: String
    let port: Int
    
    init(clientId: String, clientSecret: String, redirectUri: String, port: Int = 3003) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectUri = redirectUri
        self.port = port
    }
}
