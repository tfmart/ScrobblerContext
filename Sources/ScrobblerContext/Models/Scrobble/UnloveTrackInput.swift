//
//  UnloveTrackInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct UnloveTrackInput: ToolInput {
    let artist: String
    let track: String
    
    static let requiredParameters = ["artist", "track"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}
