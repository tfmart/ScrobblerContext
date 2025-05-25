//
//  SessionPersistenceError.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

enum SessionPersistenceError: Error, LocalizedError {
    case keychainError(String)
    case fileError(String)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .keychainError(let message):
            return "Keychain error: \(message)"
        case .fileError(let message):
            return "File storage error: \(message)"
        case .invalidData:
            return "Invalid session data format"
        }
    }
}
