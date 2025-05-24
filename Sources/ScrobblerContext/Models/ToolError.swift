//
//  ToolError.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 24/05/25.
//

import Foundation

enum ToolError: Error, LocalizedError {
    case missingParameter(String)
    case invalidParameterType(String, expected: String)
    case authenticationRequired
    case lastFMError(String)
    case jsonSerializationFailed
    
    var errorDescription: String? {
        switch self {
        case .missingParameter(let param):
            return "Missing required parameter: \(param)"
        case .invalidParameterType(let param, let expected):
            return "Invalid type for parameter '\(param)', expected: \(expected)"
        case .authenticationRequired:
            return "Authentication required for this operation"
        case .lastFMError(let message):
            return "Last.fm API error: \(message)"
        case .jsonSerializationFailed:
            return "Failed to serialize result to JSON"
        }
    }
}
