//
//  AddTrackTagsInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct AddTrackTagsInput: ToolInput {
    let track: String
    let artist: String
    let tags: [String]
    
    static let requiredParameters = ["track", "artist", "tags"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}
