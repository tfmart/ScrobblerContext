//
//  GetArtistInfoInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetArtistInfoInput: ToolInput {
    let name: String
    let autocorrect: Bool
    let username: String?
    let language: String
    
    static let requiredParameters = ["name"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "autocorrect": true,
        "username": "",
        "language": "en"
    ]
}
