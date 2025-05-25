//
//  ScrobbleTrackInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct ScrobbleTrackInput: ToolInput {
    let artist: String
    let track: String
    let timestamp: Date?
    let album: String?
    let albumArtist: String?
    let trackNumber: Int?
    let duration: Int?
    let chosenByUser: Bool?
    let mbid: String?
    
    static let requiredParameters = ["artist", "track"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "timestamp": 0,
        "album": "",
        "album_artist": "",
        "track_number": 0,
        "duration": 0,
        "chosen_by_user": false,
        "mbid": ""
    ]
}
