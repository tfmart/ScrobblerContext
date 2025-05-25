//
//  GetArtistTagsInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetArtistTagsInput: ToolInput {
    let name: String
    let user: String?
    let autocorrect: Bool
    
    static let requiredParameters = ["name"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "user": "",
        "autocorrect": true
    ]
}
