//
//  ConfigurationError.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 24/05/25.
//

import Foundation

enum ConfigurationError: Error, LocalizedError {
    case missingEnvironmentVariable(String)
    
    var errorDescription: String? {
        switch self {
        case .missingEnvironmentVariable(let key):
            return "Missing required environment variable: \(key)"
        }
    }
}
