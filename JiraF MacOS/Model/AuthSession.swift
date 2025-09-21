//
//  AuthSession.swift
//  JiraF MacOS
//
//  Created by MD RUBEL on 9/20/25.
//

import Foundation

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let cloudId: String
    
    var timeRemaining: TimeInterval { expiresAt.timeIntervalSinceNow }
    var isExpired: Bool { timeRemaining <= 0 }
    var isValidForAtLeastTenMinutes: Bool { timeRemaining >= 600 }
}
