//
//  AddArtistTagsInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct AddArtistTagsInput: ToolInput {
    let artist: String
    let tags: [String]
    
    static let requiredParameters = ["artist", "tags"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}
