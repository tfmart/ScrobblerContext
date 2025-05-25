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
        
        // Convert string to ToolName enum for type-safe validation
        guard let tool = ToolName(rawValue: toolName) else {
            throw ToolError.lastFMError("Unknown tool: \(toolName)")
        }
        
        switch tool {
        // Authentication tools
        case .authenticateUser:
            try validateRequired(["username", "password"], in: arguments)
            
        case .setSessionKey:
            try validateRequired(["session_key"], in: arguments)
            
        case .checkAuthStatus:
            // No required parameters
            break
            
        // Artist tools
        case .searchArtist:
            try validateRequired(["query"], in: arguments)
            try validateOptionalLimit(in: arguments)
            try validateOptionalPage(in: arguments)
            
        case .getArtistInfo:
            try validateRequired(["name"], in: arguments)
            
        case .getSimilarArtists:
            try validateRequired(["name"], in: arguments)
            try validateOptionalLimit(in: arguments)
            
        case .addArtistTags:
            try validateRequired(["artist", "tags"], in: arguments)
            
        case .getArtistCorrection:
            try validateRequired(["artist"], in: arguments)
            
        case .getArtistTags:
            try validateRequired(["name"], in: arguments)
            
        case .getArtistTopAlbums, .getArtistTopTracks:
            try validateRequired(["name"], in: arguments)
            try validateOptionalLimit(in: arguments)
            try validateOptionalPage(in: arguments)
            
        case .removeArtistTag:
            try validateRequired(["artist", "tag"], in: arguments)
            
        // Album tools
        case .searchAlbum:
            try validateRequired(["query"], in: arguments)
            try validateOptionalLimit(in: arguments)
            try validateOptionalPage(in: arguments)
            
        case .getAlbumInfo:
            try validateRequired(["album", "artist"], in: arguments)
            
        // Track tools
        case .searchTrack:
            try validateRequired(["query"], in: arguments)
            try validateOptionalLimit(in: arguments)
            try validateOptionalPage(in: arguments)
            
        case .getTrackInfo, .getSimilarTracks:
            try validateRequired(["track", "artist"], in: arguments)
            if tool == .getSimilarTracks {
                // Note: limit is optional for getSimilarTracks and can be nil
                if let limitValue = arguments["limit"] {
                    _ = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000)
                }
            }
            
        // User tools
        case .getUserRecentTracks:
            try validateRequired(["username"], in: arguments)
            try validateOptionalUserLimit(toolName: tool.rawValue, in: arguments)
            try validateOptionalPage(in: arguments)
            try validateOptionalTimestamps(in: arguments)
            
        case .getUserTopArtists, .getUserTopTracks:
            try validateRequired(["username"], in: arguments)
            try validateOptionalUserLimit(toolName: tool.rawValue, in: arguments)
            try validateOptionalPage(in: arguments)
            
        case .getUserInfo:
            try validateRequired(["username"], in: arguments)
            
        // Scrobble tools
        case .scrobbleTrack, .updateNowPlaying, .loveTrack, .unloveTrack:
            try validateRequired(["artist", "track"], in: arguments)
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
        let maxLimit = toolName == ToolName.getUserRecentTracks.rawValue ? 200 : 1000
        _ = try arguments.getValidatedInt(for: "limit", min: 1, max: maxLimit)
    }
    
    private func validateOptionalPage(in arguments: [String: (any Sendable)]) throws {
        _ = try arguments.getValidatedInt(for: "page", min: 1, max: Int.max)
    }
    
    private func validateOptionalTimestamps(in arguments: [String: (any Sendable)]) throws {
        // Validate start_date if provided
        if let startTimestamp = arguments.getInt(for: "start_date") {
            guard startTimestamp > 0 else {
                throw ToolError.invalidParameterType("start_date", expected: "positive Unix timestamp")
            }
        }
        
        // Validate end_date if provided
        if let endTimestamp = arguments.getInt(for: "end_date") {
            guard endTimestamp > 0 else {
                throw ToolError.invalidParameterType("end_date", expected: "positive Unix timestamp")
            }
        }
        
        // Validate that end_date is after start_date if both are provided
        if let startTimestamp = arguments.getInt(for: "start_date"),
           let endTimestamp = arguments.getInt(for: "end_date"),
           endTimestamp <= startTimestamp {
            throw ToolError.invalidParameterType("end_date", expected: "timestamp after start_date")
        }
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
    private func handleLastFMError(_ error: MCPError) -> ToolError {
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
