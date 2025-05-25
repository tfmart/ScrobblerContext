//
//  ScrobbleMultipleTracksInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct ScrobbleMultipleTracksInput: ToolInput {
    let tracks: [[String: Any]]
    
    static let requiredParameters = ["tracks"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}
