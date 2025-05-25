//
//  GetUserPersonalTagsForArtistsInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetUserPersonalTagsForArtistsInput: ToolInput {
    let username: String
    let tag: String
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["user", "tag"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "limit": 50,
        "page": 1
    ]
}
