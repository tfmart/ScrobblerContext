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
    case authenticationFailed(String)
    case lastFMError(String)
    case jsonSerializationFailed
    case networkError(String)
    case invalidOAuthCallback(String)
    case oauthTimeout
    
    var errorDescription: String? {
        switch self {
        case .missingParameter(let param):
            return "Missing required parameter: \(param)"
        case .invalidParameterType(let param, let expected):
            return "Invalid type for parameter '\(param)', expected: \(expected)"
        case .authenticationRequired:
            return "Authentication required for this operation. Please authenticate using 'authenticate_browser' or 'set_session_key'"
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .lastFMError(let message):
            return "Last.fm API error: \(message)"
        case .jsonSerializationFailed:
            return "Failed to serialize result to JSON"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidOAuthCallback(let message):
            return "Invalid OAuth callback: \(message)"
        case .oauthTimeout:
            return "OAuth authentication timed out"
        }
    }
}
