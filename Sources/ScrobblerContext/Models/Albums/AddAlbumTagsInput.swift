//
//  AddAlbumTagsInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct AddAlbumTagsInput: ToolInput {
    let album: String
    let artist: String
    let tags: [String]
    
    static let requiredParameters = ["album", "artist", "tags"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}
