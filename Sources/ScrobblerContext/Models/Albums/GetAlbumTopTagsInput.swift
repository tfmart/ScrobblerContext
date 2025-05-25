//
//  GetAlbumTopTagsInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetAlbumTopTagsInput: ToolInput {
    let album: String
    let artist: String
    let autocorrect: Bool
    
    static let requiredParameters = ["album", "artist"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "autocorrect": true
    ]
}
