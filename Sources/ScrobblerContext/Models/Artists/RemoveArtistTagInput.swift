//
//  RemoveArtistTagInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct RemoveArtistTagInput: ToolInput {
    let artist: String
    let tag: String
    
    static let requiredParameters = ["artist", "tag"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}
