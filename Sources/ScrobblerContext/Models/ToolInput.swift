//
//  ToolInput.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

// MARK: - Tool Input Models

/// Base protocol for all tool inputs
protocol ToolInput {
    static var requiredParameters: [String] { get }
    static var optionalParameters: [String: (any Sendable)?] { get }
}
