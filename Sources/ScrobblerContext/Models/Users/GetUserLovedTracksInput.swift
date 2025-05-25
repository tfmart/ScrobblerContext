//
//  GetUserLovedTracksInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetUserLovedTracksInput: ToolInput {
    let username: String
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["user"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "limit": 50,
        "page": 1
    ]
}
