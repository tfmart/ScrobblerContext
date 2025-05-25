//
//  RemoveTrackTagInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct RemoveTrackTagInput: ToolInput {
    let track: String
    let artist: String
    let tag: String
    
    static let requiredParameters = ["track", "artist", "tag"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}
