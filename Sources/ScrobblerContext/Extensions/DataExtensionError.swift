//
//  DataExtensions.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 17/05/25.
//

import Foundation


// MARK: - Dictionary Extensions

extension Dictionary where Key == String, Value == (any Sendable) {
    /// Safely extract a string value for a given key
    func getString(for key: String) -> String? {
        return self[key] as? String ?? (self[key].map { "\($0)" })
    }
    
    /// Safely extract an integer value for a given key with flexible parsing
    func getInt(for key: String) -> Int? {
        guard let value = self[key] else { return nil }
        
        // Try direct Int cast first
        if let intValue = value as? Int {
            return intValue
        }
        
        // Try String conversion
        if let stringValue = value as? String {
            return Int(stringValue)
        }
        
        // Try Double conversion (for JSON numbers)
        if let doubleValue = value as? Double, doubleValue.truncatingRemainder(dividingBy: 1) == 0 {
            return Int(doubleValue)
        }
        
        // Try Float conversion
        if let floatValue = value as? Float, floatValue.truncatingRemainder(dividingBy: 1) == 0 {
            return Int(floatValue)
        }
        
        // Handle MCP Value type by converting to string first
        let stringRepresentation = "\(value)"
        if let intFromString = Int(stringRepresentation) {
            return intFromString
        }
        
        return nil
    }
    
    /// Safely extract an integer with bounds validation
    func getValidatedInt(for key: String, min: Int = Int.min, max: Int = Int.max, default defaultValue: Int? = nil) throws -> Int? {
        if self[key] != nil {
            guard let parsedInt = self.getInt(for: key) else {
                throw ToolError.invalidParameterType(key, expected: "integer between \(min) and \(max)")
            }
            
            guard parsedInt >= min && parsedInt <= max else {
                throw ToolError.invalidParameterType(key, expected: "integer between \(min) and \(max)")
            }
            
            return parsedInt
        }
        
        return defaultValue
    }
    
    /// Safely extract a boolean value for a given key
    func getBool(for key: String) -> Bool? {
        if let boolValue = self[key] as? Bool {
            return boolValue
        } else if let stringValue = self[key] as? String {
            return Bool(stringValue)
        } else if let intValue = self[key] as? Int {
            return intValue != 0
        }
        return nil
    }
    
    /// Get value with default fallback
    func getValue<T>(for key: String, default defaultValue: T) -> T {
        return self[key] as? T ?? defaultValue
    }
}

// MARK: - String Extensions

extension String {
    /// Validate if string is a valid Last.fm username format
    var isValidLastFMUsername: Bool {
        // Last.fm usernames are typically 2-15 characters, alphanumeric plus some special chars
        let pattern = "^[a-zA-Z0-9_-]{2,15}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: self)
    }
    
    /// Clean string for safe logging (remove potential sensitive data)
    var cleanedForLogging: String {
        // Remove common patterns that might contain sensitive data
        return self
            .replacingOccurrences(of: #"password\s*[:=]\s*[^\s,}]+"#, with: "password: ***", options: .regularExpression)
            .replacingOccurrences(of: #"api_key\s*[:=]\s*[^\s,}]+"#, with: "api_key: ***", options: .regularExpression)
            .replacingOccurrences(of: #"session_key\s*[:=]\s*[^\s,}]+"#, with: "session_key: ***", options: .regularExpression)
    }
}

// MARK: - Date Extensions

extension Date {
    /// Format date as ISO8601 string
    var iso8601String: String {
        return ISO8601DateFormatter().string(from: self)
    }
    
    /// Format date for Last.fm API (Unix timestamp)
    var lastFMTimestamp: Int {
        return Int(self.timeIntervalSince1970)
    }
}

// MARK: - Optional Extensions

extension Optional where Wrapped == String {
    /// Get string value or empty string if nil
    var orEmpty: String {
        return self ?? ""
    }
    
    /// Check if optional string is nil or empty
    var isNilOrEmpty: Bool {
        return self?.isEmpty != false
    }
}

// MARK: - Error Types

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

// MARK: - Result Extensions

extension Result where Success == ToolResult, Failure == Error {
    /// Convert Result to ToolResult for consistent error handling
    func toToolResult() -> ToolResult {
        switch self {
        case .success(let toolResult):
            return toolResult
        case .failure(let error):
            return ToolResult.failure(error: error.localizedDescription)
        }
    }
}
