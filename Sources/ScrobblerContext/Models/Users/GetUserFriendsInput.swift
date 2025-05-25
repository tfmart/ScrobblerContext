//
//  GetUserFriendsInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetUserFriendsInput: ToolInput {
    let username: String
    let recentTracks: Bool
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["user"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "recent_tracks": false,
        "limit": 50,
        "page": 1
    ]
}
