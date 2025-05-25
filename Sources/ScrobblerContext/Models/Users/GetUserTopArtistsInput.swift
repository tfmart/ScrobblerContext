//
//  GetUserTopArtistsInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetUserTopArtistsInput: ToolInput {
    let username: String
    let period: String
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["username"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "period": "overall",
        "limit": 10,
        "page": 1
    ]
}
