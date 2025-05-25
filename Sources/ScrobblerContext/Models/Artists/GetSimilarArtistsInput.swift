//
//  GetSimilarArtistsInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetSimilarArtistsInput: ToolInput {
    let name: String
    let limit: Int
    let autocorrect: Bool
    
    static let requiredParameters = ["name"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "limit": 10,
        "autocorrect": true
    ]
}
