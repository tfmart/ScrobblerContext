//
//  GetUserTopTagsInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetUserTopTagsInput: ToolInput {
    let username: String
    let limit: Int?
    
    static let requiredParameters = ["username"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "limit": nil
    ]
}
