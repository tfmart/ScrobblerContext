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
