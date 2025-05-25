//
//  UpdateNowPlayingInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct UpdateNowPlayingInput: ToolInput {
    let artist: String
    let track: String
    let album: String?
    let trackNumber: Int?
    let context: String?
    let mbid: String?
    let duration: Int?
    let albumArtist: String?
    
    static let requiredParameters = ["artist", "track"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "album": "",
        "track_number": 0,
        "context": "",
        "mbid": "",
        "duration": 0,
        "album_artist": ""
    ]
}
