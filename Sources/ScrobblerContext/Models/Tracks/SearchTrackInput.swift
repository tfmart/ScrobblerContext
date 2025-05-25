//
//  SearchTrackInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct SearchTrackInput: ToolInput {
    let query: String
    let artist: String?
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["query"]
    static let optionalParameters: [String: (any Sendable)?] = ["artist": "", "limit": 10, "page": 1]
}
