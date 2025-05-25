//
//  GetTrackTopTagsInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetTrackTopTagsInput: ToolInput {
    let track: String
    let artist: String
    let autocorrect: Bool
    
    static let requiredParameters = ["track", "artist"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "autocorrect": true
    ]
}
