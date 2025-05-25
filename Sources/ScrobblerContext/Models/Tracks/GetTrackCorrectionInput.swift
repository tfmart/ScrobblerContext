//
//  GetTrackCorrectionInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetTrackCorrectionInput: ToolInput {
    let track: String
    let artist: String
    
    static let requiredParameters = ["track", "artist"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}
