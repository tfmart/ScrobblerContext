//
//  AuthenticateInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

struct AuthenticateInput: ToolInput {
    let username: String
    let password: String
    
    static let requiredParameters = ["username", "password"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}
