//
//  GetUserRecentTracksInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetUserRecentTracksInput: ToolInput {
    let username: String
    let limit: Int
    let page: Int
    let startDate: Date?
    let extended: Bool
    let endDate: Date?
    
    static let requiredParameters = ["username"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "limit": 50,
        "page": 1,
        "start_date": 0,
        "extended": false,
        "end_date": 0
    ]
}
