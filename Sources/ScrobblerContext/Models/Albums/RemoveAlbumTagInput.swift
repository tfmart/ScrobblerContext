//
//  RemoveAlbumTagInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct RemoveAlbumTagInput: ToolInput {
    let album: String
    let artist: String
    let tag: String
    
    static let requiredParameters = ["album", "artist", "tag"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}
