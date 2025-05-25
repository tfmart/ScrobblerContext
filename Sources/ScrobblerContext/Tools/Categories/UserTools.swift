//
//  UserTools.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 24/05/25.
//

import Foundation
import MCP
@preconcurrency import ScrobbleKit
import Logging

/// User-related tools for the Last.fm MCP Server
struct UserTools {
    private let lastFMService: LastFMService
    private let logger = Logger(label: "com.lastfm.mcp-server.user")
    
    init(lastFMService: LastFMService) {
        self.lastFMService = lastFMService
    }
    
    // MARK: - Tool Definitions
    
    static func createTools() -> [Tool] {
        return [
            createGetUserRecentTracksTool(),
            createGetUserTopArtistsTool(),
            createGetUserTopTracksTool(),
            createGetUserInfoTool()
        ]
    }
    
    private static func createGetUserRecentTracksTool() -> Tool {
        return Tool(
            name: "get_user_recent_tracks",
            description: "Get a user's recently played tracks from Last.fm",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "username": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username to get recent tracks for")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Maximum number of recent tracks to return (1-200)"),
                        "default": .int(10),
                        "minimum": .int(1),
                        "maximum": .int(200)
                    ]),
                    "page": .object([
                        "type": .string("integer"),
                        "description": .string("Page number for pagination (starts from 1)"),
                        "default": .int(1),
                        "minimum": .int(1)
                    ])
                ]),
                "required": .array([.string("username")])
            ])
        )
    }
    
    private static func createGetUserTopArtistsTool() -> Tool {
        return Tool(
            name: "get_user_top_artists",
            description: "Get a user's top artists based on their listening history",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "username": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username to get top artists for")
                    ]),
                    "period": .object([
                        "type": .string("string"),
                        "description": .string("Time period for top artists"),
                        "enum": .array([
                            .string("overall"),
                            .string("7day"),
                            .string("1month"),
                            .string("3month"),
                            .string("6month"),
                            .string("12month")
                        ]),
                        "default": .string("overall")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Maximum number of top artists to return (1-1000)"),
                        "default": .int(10),
                        "minimum": .int(1),
                        "maximum": .int(1000)
                    ]),
                    "page": .object([
                        "type": .string("integer"),
                        "description": .string("Page number for pagination (starts from 1)"),
                        "default": .int(1),
                        "minimum": .int(1)
                    ])
                ]),
                "required": .array([.string("username")])
            ])
        )
    }
    
    private static func createGetUserTopTracksTool() -> Tool {
        return Tool(
            name: "get_user_top_tracks",
            description: "Get a user's top tracks based on their listening history",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "username": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username to get top tracks for")
                    ]),
                    "period": .object([
                        "type": .string("string"),
                        "description": .string("Time period for top tracks"),
                        "enum": .array([
                            .string("overall"),
                            .string("7day"),
                            .string("1month"),
                            .string("3month"),
                            .string("6month"),
                            .string("12month")
                        ]),
                        "default": .string("overall")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Maximum number of top tracks to return (1-1000)"),
                        "default": .int(10),
                        "minimum": .int(1),
                        "maximum": .int(1000)
                    ]),
                    "page": .object([
                        "type": .string("integer"),
                        "description": .string("Page number for pagination (starts from 1)"),
                        "default": .int(1),
                        "minimum": .int(1)
                    ])
                ]),
                "required": .array([.string("username")])
            ])
        )
    }
    
    private static func createGetUserInfoTool() -> Tool {
        return Tool(
            name: "get_user_info",
            description: "Get detailed information about a Last.fm user's profile",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "username": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username to get profile information for")
                    ])
                ]),
                "required": .array([.string("username")])
            ])
        )
    }
    
    // MARK: - Tool Execution
    
    func execute(toolName: String, arguments: [String: (any Sendable)]) async throws -> ToolResult {
        logger.info("Executing user tool: \(toolName)")
        
        switch toolName {
        case "get_user_recent_tracks":
            return try await executeGetUserRecentTracks(arguments: arguments)
        case "get_user_top_artists":
            return try await executeGetUserTopArtists(arguments: arguments)
        case "get_user_top_tracks":
            return try await executeGetUserTopTracks(arguments: arguments)
        case "get_user_info":
            return try await executeGetUserInfo(arguments: arguments)
        default:
            throw ToolError.lastFMError("Unknown user tool: \(toolName)")
        }
    }
    
    // MARK: - Individual Tool Implementations
    
    private func executeGetUserRecentTracks(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetUserRecentTracksInput(arguments)
        
        do {
            let recentTracks = try await lastFMService.getUserRecentTracks(
                user: input.username,
                limit: input.limit
            )
            
            logger.info("Retrieved \(recentTracks.results.count) recent tracks for user: \(input.username)")
            
            let result = ResponseFormatters.format(recentTracks)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get recent tracks for user '\(input.username)': \(error)")
            return ToolResult.failure(error: "Failed to get recent tracks: \(error.localizedDescription)")
        }
    }
    
    private func executeGetUserTopArtists(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetUserTopArtistsInput(arguments)
        
        do {
            let topArtists = try await lastFMService.getUserTopArtists(
                user: input.username,
                limit: input.limit
            )
            
            logger.info("Retrieved \(topArtists.results.count) top artists for user: \(input.username) (period: \(input.period))")
            
            let result = ResponseFormatters.format(topArtists)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get top artists for user '\(input.username)': \(error)")
            return ToolResult.failure(error: "Failed to get top artists: \(error.localizedDescription)")
        }
    }
    
    private func executeGetUserTopTracks(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetUserTopTracksInput(arguments)
        
        do {
            let topTracks = try await lastFMService.getUserTopTracks(
                user: input.username,
                limit: input.limit
            )
            
            logger.info("Retrieved \(topTracks.results.count) top tracks for user: \(input.username) (period: \(input.period))")
            
            let result = ResponseFormatters.format(topTracks)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get top tracks for user '\(input.username)': \(error)")
            return ToolResult.failure(error: "Failed to get top tracks: \(error.localizedDescription)")
        }
    }
    
    private func executeGetUserInfo(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetUserInfoInput(arguments)
        
        do {
            let userInfo = try await lastFMService.getUserInfo(username: input.username)
            
            logger.info("Retrieved user info for: \(input.username)")
            
            let result = ResponseFormatters.formatUserInfo(userInfo)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get user info for '\(input.username)': \(error)")
            return ToolResult.failure(error: "Failed to get user info: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Input Parsing Helpers
    
    private func parseGetUserRecentTracksInput(_ arguments: [String: (any Sendable)]) throws -> GetUserRecentTracksInput {
        guard let usernameValue = arguments["username"] else {
            throw ToolError.missingParameter("username")
        }
        
        let username = "\(usernameValue)"
        let limit = try arguments.getValidatedInt(for: "limit", min: 1, max: 200, default: 10) ?? 10
        let page = try arguments.getValidatedInt(for: "page", min: 1, max: Int.max, default: 1) ?? 1
        
        return GetUserRecentTracksInput(
            username: username,
            limit: limit,
            page: page
        )
    }
    
    private func parseGetUserTopArtistsInput(_ arguments: [String: (any Sendable)]) throws -> GetUserTopArtistsInput {
        guard let usernameValue = arguments["username"] else {
            throw ToolError.missingParameter("username")
        }
        
        let username = "\(usernameValue)"
        let period = arguments.getString(for: "period") ?? "overall"
        let limit = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000, default: 10) ?? 10
        let page = try arguments.getValidatedInt(for: "page", min: 1, max: Int.max, default: 1) ?? 1
        
        // Validate period
        let validPeriods = ["overall", "7day", "1month", "3month", "6month", "12month"]
        guard validPeriods.contains(period) else {
            throw ToolError.invalidParameterType("period", expected: "one of: \(validPeriods.joined(separator: ", "))")
        }
        
        return GetUserTopArtistsInput(
            username: username,
            period: period,
            limit: limit,
            page: page
        )
    }
    
    private func parseGetUserTopTracksInput(_ arguments: [String: (any Sendable)]) throws -> GetUserTopTracksInput {
        guard let usernameValue = arguments["username"] else {
            throw ToolError.missingParameter("username")
        }
        
        let username = "\(usernameValue)"
        let period = arguments.getString(for: "period") ?? "overall"
        let limit = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000, default: 10) ?? 10
        let page = try arguments.getValidatedInt(for: "page", min: 1, max: Int.max, default: 1) ?? 1
        
        // Validate period
        let validPeriods = ["overall", "7day", "1month", "3month", "6month", "12month"]
        guard validPeriods.contains(period) else {
            throw ToolError.invalidParameterType("period", expected: "one of: \(validPeriods.joined(separator: ", "))")
        }
        
        return GetUserTopTracksInput(
            username: username,
            period: period,
            limit: limit,
            page: page
        )
    }
    
    private func parseGetUserInfoInput(_ arguments: [String: (any Sendable)]) throws -> GetUserInfoInput {
        guard let usernameValue = arguments["username"] else {
            throw ToolError.missingParameter("username")
        }
        
        let username = "\(usernameValue)"
        
        return GetUserInfoInput(username: username)
    }
}

// MARK: - Input Models for User Tools
struct GetUserTopTracksInput: ToolInput {
    let username: String
    let period: String
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["username"]
    static let optionalParameters: [String: (any Sendable)] = [
        "period": "overall",
        "limit": 10,
        "page": 1
    ]
}

struct GetUserInfoInput: ToolInput {
    let username: String
    
    static let requiredParameters = ["username"]
    static let optionalParameters: [String: (any Sendable)] = [:]
}
