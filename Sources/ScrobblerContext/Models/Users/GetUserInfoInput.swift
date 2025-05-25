//
//  GetUserInfoInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct GetUserInfoInput: ToolInput {
    let username: String
    
    static let requiredParameters = ["username"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}
