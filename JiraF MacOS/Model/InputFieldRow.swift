//
//  InputFieldRow.swift
//  JiraF MacOS
//
//  Created by MD RUBEL on 9/23/25.
//

import Foundation

struct InputFieldRow: Identifiable, Hashable {
    let id = UUID()
    var title: String = ""
    var devHours: String = ""
    var solutionHours: String = ""
}
