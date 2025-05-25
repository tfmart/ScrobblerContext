//
//  GetArtistCorrectionInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetArtistCorrectionInput: ToolInput {
    let artist: String
    
    static let requiredParameters = ["artist"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}
