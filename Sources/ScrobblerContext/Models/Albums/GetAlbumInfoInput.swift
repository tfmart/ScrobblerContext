//
//  GetAlbumInfoInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetAlbumInfoInput: ToolInput {
    let album: String
    let artist: String
    let autocorrect: Bool
    let username: String?
    let language: String
    
    static let requiredParameters = ["album", "artist"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "autocorrect": true,
        "user": "",
        "language": "en"
    ]
}
