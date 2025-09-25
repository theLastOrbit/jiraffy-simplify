//
//  JiraPayload.swift
//  JiraF MacOS
//
//  Created by MD RUBEL on 9/25/25.
//


import Foundation

struct JiraPayload: Encodable {
    
    struct Fields: Encodable {
        struct IssueType: Encodable { let id: String }
        struct Project: Encodable { let id: String }
        struct Parent: Encodable { let key: String }
        struct RichText: Encodable {
            struct Block: Encodable {
                struct InlineText: Encodable {
                    let type: String = "text"
                    let text: String
                }
                let type: String = "paragraph"
                let content: [InlineText]
            }
            let version: Int = 1
            let type: String = "doc"
            let content: [Block]
        }
        struct Account: Encodable { let accountId: String }
        struct SquadValue: Encodable { let value: String }
        let summary: String
        let issuetype: IssueType
        let project: Project
        let parent: Parent
        let description: RichText
        let assignee: Account
        let reporter: Account
        let customfield_10501: SquadValue
        let customfield_10800: Double?
        let customfield_11405: Double?
    }
    
    struct Transition: Encodable {
        let id: String
    }
    
    
    let fields: Fields
    let transition: Transition
}

struct JiraTicket: Identifiable {
    var id: String { key }
    
    let key: String
    let summary: String
}
