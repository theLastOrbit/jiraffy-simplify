//
//  JiraUser.swift
//  JiraF MacOS
//
//  Created by MD RUBEL on 9/21/25.
//


struct JiraUser: Codable, Equatable, Identifiable {
    let accountId: String
    let displayName: String
    var id: String { accountId }
    
    enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case displayName = "name"
    }
}
