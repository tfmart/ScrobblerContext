//
//  ToolExecutor.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 17/05/25.
//

import Foundation
import MCP
import Logging

/// Handles execution of MCP tool calls with proper error handling and logging
struct ToolExecutor {
    private let toolRegistry: ToolRegistry
    private let logger = Logger(label: "com.lastfm.mcp-server.executor")
    
    init(toolRegistry: ToolRegistry) {
        self.toolRegistry = toolRegistry
    }
    
    // MARK: - Public Interface
    
    /// Execute a tool call and return formatted result
    func execute(toolName: String, arguments: [String: (any Sendable)]?) async throws -> CallTool.Result {
        let startTime = Date()
        logger.info("Starting execution of tool: \(toolName)")
        
        // Log arguments for debugging (but sanitize sensitive data)
        let sanitizedArgs = sanitizeArguments(arguments ?? [:])
        logger.debug("Tool arguments: \(sanitizedArgs)")
        
        do {
            // Execute the tool
            let result = try await toolRegistry.executeTool(
                name: toolName,
                arguments: arguments ?? [:]
            )
            
            // Convert result to JSON string
            let jsonResult = try result.toJSON()
            
            // Log execution time
            let executionTime = Date().timeIntervalSince(startTime)
            logger.info("Tool \(toolName) completed successfully in \(String(format: "%.3f", executionTime))s")
            
            // Return MCP result
            return CallTool.Result(content: [.text(.init(jsonResult))])
            
        } catch let toolError as ToolError {
            logger.error("Tool error in \(toolName): \(toolError.localizedDescription)")
            
            let errorResult = ToolResult.failure(error: toolError.localizedDescription)
            let jsonResult = try errorResult.toJSON()
            
            return CallTool.Result(content: [.text(.init(jsonResult))])
            
        } catch {
            logger.error("Unexpected error in \(toolName): \(error)")
            
            let errorResult = ToolResult.failure(error: "Internal error: \(error.localizedDescription)")
            let jsonResult = try errorResult.toJSON()
            
            return CallTool.Result(content: [.text(.init(jsonResult))])
        }
    }
    
    /// Get list of all available tools
    func getAvailableTools() -> [Tool] {
        logger.info("Providing list of available tools")
        return toolRegistry.getAllTools()
    }
    
    /// Get tools for a specific category
    func getToolsForCategory(_ category: ToolCategory) -> [Tool] {
        logger.info("Providing tools for category: \(category.description)")
        return toolRegistry.getToolsForCategory(category)
    }
    
    // MARK: - Validation
    
    /// Validate tool arguments against expected schema
    func validateToolArguments(toolName: String, arguments: [String: (any Sendable)]) throws {
        logger.debug("Validating arguments for tool: \(toolName)")
        
        // This is a basic validation - in a more sophisticated implementation,
        // you might validate against the actual JSON schema defined in the tools
        
        switch toolName {
        // Authentication tools
        case "authenticate_user":
            try validateRequired(["username", "password"], in: arguments)
            
        case "set_session_key":
            try validateRequired(["session_key"], in: arguments)
            
        // Artist tools
        case "search_artist":
            try validateRequired(["query"], in: arguments)
            try validateOptionalLimit(in: arguments)
            
        case "get_artist_info":
            try validateRequired(["name"], in: arguments)
            
        case "get_similar_artists":
            try validateRequired(["name"], in: arguments)
            try validateOptionalLimit(in: arguments)
            
        // Album tools
        case "search_album":
            try validateRequired(["query"], in: arguments)
            try validateOptionalLimit(in: arguments)
            
        case "get_album_info":
            try validateRequired(["album", "artist"], in: arguments)
            
        // Track tools
        case "search_track":
            try validateRequired(["query"], in: arguments)
            try validateOptionalLimit(in: arguments)
            
        case "get_track_info", "get_similar_tracks":
            try validateRequired(["track", "artist"], in: arguments)
            if toolName == "get_similar_tracks" {
                try validateOptionalLimit(in: arguments)
            }
            
        // User tools
        case "get_user_recent_tracks", "get_user_top_artists", "get_user_top_tracks", "get_user_info":
            try validateRequired(["username"], in: arguments)
            // For tools with limit/page parameters
            if toolName != "get_user_info" {
                try validateOptionalUserLimit(toolName: toolName, in: arguments)
                try validateOptionalPage(in: arguments)
            }
            
        // Future tool validations
        case "search_album", "search_track":
            try validateRequired(["query"], in: arguments)
            
        case "get_album_info":
            try validateRequired(["album", "artist"], in: arguments)
            
        case "get_user_recent_tracks", "get_user_top_artists":
            try validateRequired(["username"], in: arguments)
            
        case "scrobble_track":
            try validateRequired(["artist", "track"], in: arguments)
            
        // Scrobble tools
        case "scrobble_track", "update_now_playing", "love_track", "unlove_track":
            try validateRequired(["artist", "track"], in: arguments)
            
        default:
            // For tools we don't know about, skip validation
            logger.debug("No specific validation rules for tool: \(toolName)")
        }
    }
    
    // MARK: - Private Helpers
    
    private func validateRequired(_ requiredParams: [String], in arguments: [String: (any Sendable)]) throws {
        for param in requiredParams {
            if arguments[param] == nil {
                throw ToolError.missingParameter(param)
            }
        }
    }
    
    private func validateOptionalLimit(in arguments: [String: (any Sendable)]) throws {
        _ = try arguments.getValidatedInt(for: "limit", min: 1, max: 50)
    }
    
    private func validateOptionalUserLimit(toolName: String, in arguments: [String: (any Sendable)]) throws {
        let maxLimit = toolName == "get_user_recent_tracks" ? 200 : 1000
        _ = try arguments.getValidatedInt(for: "limit", min: 1, max: maxLimit)
    }
    
    private func validateOptionalPage(in arguments: [String: (any Sendable)]) throws {
        _ = try arguments.getValidatedInt(for: "page", min: 1, max: Int.max)
    }
    
    private func sanitizeArguments(_ arguments: [String: (any Sendable)]) -> [String: (any Sendable)] {
        var sanitized = arguments
        
        // Remove or mask sensitive fields
        let sensitiveKeys = ["password", "session_key", "api_key", "secret"]
        
        for key in sensitiveKeys {
            if sanitized[key] != nil {
                sanitized[key] = "***REDACTED***"
            }
        }
        
        return sanitized
    }
}

// MARK: - Error Handling Extensions

extension ToolExecutor {
    
    /// Handle specific Last.fm API errors with appropriate user messages
    private func handleLastFMError(_ error: Error) -> ToolError {
        let errorMessage = error.localizedDescription.lowercased()
        
        if errorMessage.contains("authentication") || errorMessage.contains("unauthorized") {
            return .authenticationRequired
        } else if errorMessage.contains("not found") {
            return .lastFMError("Resource not found")
        } else if errorMessage.contains("rate limit") {
            return .lastFMError("Rate limit exceeded. Please try again later.")
        } else {
            return .lastFMError(error.localizedDescription)
        }
    }
}

// MARK: - Performance Monitoring

extension ToolExecutor {
    
    /// Monitor tool execution performance
    private func logPerformanceMetrics(toolName: String, executionTime: TimeInterval, success: Bool) {
        let status = success ? "SUCCESS" : "FAILURE"
        logger.info("METRICS: \(toolName) | \(status) | \(String(format: "%.3f", executionTime))s")
        
        // In a production environment, you might want to send these metrics
        // to a monitoring service like CloudWatch, DataDog, etc.
    }
}
