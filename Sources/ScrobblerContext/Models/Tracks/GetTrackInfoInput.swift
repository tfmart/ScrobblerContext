//
//  GetTrackInfoInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetTrackInfoInput: ToolInput {
    let track: String
    let artist: String
    let username: String?
    let autocorrect: Bool
    let language: String
    
    static let requiredParameters = ["track", "artist"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "user": "",
        "autocorrect": false,
        "language": "en"
    ]
}
