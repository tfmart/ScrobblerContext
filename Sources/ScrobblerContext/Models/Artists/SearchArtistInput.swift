//
//  SearchArtistInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct SearchArtistInput: ToolInput {
    let query: String
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["query"]
    static let optionalParameters: [String: (any Sendable)?] = ["limit": 10, "page": 1]
}
