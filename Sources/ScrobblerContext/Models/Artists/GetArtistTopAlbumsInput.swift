//
//  GetArtistTopAlbumsInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetArtistTopAlbumsInput: ToolInput {
    let name: String
    let limit: Int
    let page: Int
    let autocorrect: Bool
    
    static let requiredParameters = ["name"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "limit": 50,
        "page": 1,
        "autocorrect": true
    ]
}
