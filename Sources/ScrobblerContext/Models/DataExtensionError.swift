//
//  DataExtensionError.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

enum DataExtensionError: Error, LocalizedError {
    case stringConversionFailed
    case invalidFormat
    case parsingFailed
    
    var errorDescription: String? {
        switch self {
        case .stringConversionFailed:
            return "Failed to convert data to string"
        case .invalidFormat:
            return "Invalid data format"
        case .parsingFailed:
            return "Failed to parse data"
        }
    }
}
