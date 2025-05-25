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
            createGetUserInfoTool(),
            createGetUserFriendsTool(),
            createGetUserLovedTracksTool(),
            createGetUserPersonalTagsForArtistsTool(),
            createGetUserTopAlbumsTool(),
            createGetUserTopTagsTool()
        ]
    }
    
    private static func createGetUserRecentTracksTool() -> Tool {
        return Tool(
            name: ToolName.getUserRecentTracks.rawValue,
            description: ToolName.getUserRecentTracks.description,
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
                        "default": .int(50),
                        "minimum": .int(1),
                        "maximum": .int(200)
                    ]),
                    "page": .object([
                        "type": .string("integer"),
                        "description": .string("Page number for pagination (starts from 1)"),
                        "default": .int(1),
                        "minimum": .int(1)
                    ]),
                    "start_date": .object([
                        "type": .string("integer"),
                        "description": .string("Unix timestamp for the earliest track to include (optional)")
                    ]),
                    "end_date": .object([
                        "type": .string("integer"),
                        "description": .string("Unix timestamp for the latest track to include (optional)")
                    ]),
                    "extended": .object([
                        "type": .string("boolean"),
                        "description": .string("Include extended data in the response (optional)"),
                        "default": .bool(false)
                    ])
                ]),
                "required": .array([.string("username")])
            ])
        )
    }
    
    private static func createGetUserTopArtistsTool() -> Tool {
        return Tool(
            name: ToolName.getUserTopArtists.rawValue,
            description: ToolName.getUserTopArtists.description,
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
            name: ToolName.getUserTopTracks.rawValue,
            description: ToolName.getUserTopTracks.description,
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
            name: ToolName.getUserInfo.rawValue,
            description: ToolName.getUserInfo.description,
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
    
    private static func createGetUserFriendsTool() -> Tool {
        return Tool(
            name: ToolName.getUserFriends.rawValue,
            description: ToolName.getUserFriends.description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "username": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username to get friends for")
                    ]),
                    "recent_tracks": .object([
                        "type": .string("boolean"),
                        "description": .string("Include information about friends' recent tracks"),
                        "default": .bool(false)
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Maximum number of friends to return (1-50)"),
                        "default": .int(50),
                        "minimum": .int(1),
                        "maximum": .int(50)
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
    
    private static func createGetUserLovedTracksTool() -> Tool {
        return Tool(
            name: ToolName.getUserLovedTracks.rawValue,
            description: ToolName.getUserLovedTracks.description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "username": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username to get loved tracks for")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Maximum number of loved tracks to return (1-50)"),
                        "default": .int(50),
                        "minimum": .int(1),
                        "maximum": .int(50)
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
    
    private static func createGetUserPersonalTagsForArtistsTool() -> Tool {
        return Tool(
            name: ToolName.getUserPersonalTagsForArtists.rawValue,
            description: ToolName.getUserPersonalTagsForArtists.description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "username": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username to get personal tags from")
                    ]),
                    "tag": .object([
                        "type": .string("string"),
                        "description": .string("The specific tag to search for")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Maximum number of artists to return (1-50)"),
                        "default": .int(50),
                        "minimum": .int(1),
                        "maximum": .int(50)
                    ]),
                    "page": .object([
                        "type": .string("integer"),
                        "description": .string("Page number for pagination (starts from 1)"),
                        "default": .int(1),
                        "minimum": .int(1)
                    ])
                ]),
                "required": .array([.string("username"), .string("tag")])
            ])
        )
    }
    
    private static func createGetUserTopAlbumsTool() -> Tool {
        return Tool(
            name: ToolName.getUserTopAlbums.rawValue,
            description: ToolName.getUserTopAlbums.description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "username": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username to get top albums for")
                    ]),
                    "period": .object([
                        "type": .string("string"),
                        "description": .string("Time period for top albums"),
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
                        "description": .string("Maximum number of top albums to return (1-50)"),
                        "default": .int(50),
                        "minimum": .int(1),
                        "maximum": .int(50)
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
    
    private static func createGetUserTopTagsTool() -> Tool {
        return Tool(
            name: ToolName.getUserTopTags.rawValue,
            description: ToolName.getUserTopTags.description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "username": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username to get top tags for")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Maximum number of top tags to return (optional, uses Last.fm default if not specified)")
                    ])
                ]),
                "required": .array([.string("username")])
            ])
        )
    }
    
    // MARK: - Tool Execution
    
    func execute(toolName: ToolName, arguments: [String: (any Sendable)]) async throws -> ToolResult {
        logger.info("Executing user tool: \(toolName.rawValue)")
        
        switch toolName {
        case .getUserRecentTracks:
            return try await executeGetUserRecentTracks(arguments: arguments)
        case .getUserTopArtists:
            return try await executeGetUserTopArtists(arguments: arguments)
        case .getUserTopTracks:
            return try await executeGetUserTopTracks(arguments: arguments)
        case .getUserInfo:
            return try await executeGetUserInfo(arguments: arguments)
        case .getUserFriends:
            return try await executeGetUserFriends(arguments: arguments)
        case .getUserLovedTracks:
            return try await executeGetUserLovedTracks(arguments: arguments)
        case .getUserPersonalTagsForArtists:
            return try await executeGetUserPersonalTagsForArtists(arguments: arguments)
        case .getUserTopAlbums:
            return try await executeGetUserTopAlbums(arguments: arguments)
        case .getUserTopTags:
            return try await executeGetUserTopTags(arguments: arguments)
        default:
            throw ToolError.lastFMError("Invalid user tool: \(toolName.rawValue)")
        }
    }
    
    // MARK: - Individual Tool Implementations
    
    private func executeGetUserRecentTracks(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetUserRecentTracksInput(arguments)
        
        do {
            let recentTracks = try await lastFMService.getUserRecentTracks(
                user: input.username,
                limit: input.limit,
                page: input.page,
                startDate: input.startDate,
                extended: input.extended,
                endDate: input.endDate
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
                period: input.period,
                limit: input.limit,
                page: input.page
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
                period: input.period,
                limit: input.limit,
                page: input.page
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
    
    private func executeGetUserFriends(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetUserFriendsInput(arguments)
        
        do {
            let friends = try await lastFMService.getUserFriends(
                user: input.username,
                recentTracks: input.recentTracks,
                limit: input.limit,
                page: input.page
            )
            
            logger.info("Retrieved \(friends.count) friends for user: \(input.username)")
            
            let result = ResponseFormatters.format(friends)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get friends for user '\(input.username)': \(error)")
            return ToolResult.failure(error: "Failed to get user friends: \(error.localizedDescription)")
        }
    }
    
    private func executeGetUserLovedTracks(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetUserLovedTracksInput(arguments)
        
        do {
            let lovedTracks = try await lastFMService.getUserLovedTracks(
                user: input.username,
                limit: input.limit,
                page: input.page
            )
            
            logger.info("Retrieved \(lovedTracks.tracks.count) loved tracks for user: \(input.username)")
            
            let result = ResponseFormatters.format(lovedTracks)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get loved tracks for user '\(input.username)': \(error)")
            return ToolResult.failure(error: "Failed to get loved tracks: \(error.localizedDescription)")
        }
    }
    
    private func executeGetUserPersonalTagsForArtists(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetUserPersonalTagsForArtistsInput(arguments)
        
        do {
            let taggedArtists = try await lastFMService.getUserPersonalTagsForArtists(
                user: input.username,
                tag: input.tag,
                limit: input.limit,
                page: input.page
            )
            
            logger.info("Retrieved \(taggedArtists.results.count) artists tagged with '\(input.tag)' by user: \(input.username)")
            
            let result = ResponseFormatters.format(taggedArtists)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get personal tagged artists for user '\(input.username)': \(error)")
            return ToolResult.failure(error: "Failed to get personal tagged artists: \(error.localizedDescription)")
        }
    }
    
    private func executeGetUserTopAlbums(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetUserTopAlbumsInput(arguments)
        
        do {
            let topAlbums = try await lastFMService.getUserTopAlbums(
                user: input.username,
                period: input.period,
                limit: input.limit,
                page: input.page
            )
            
            logger.info("Retrieved \(topAlbums.results.count) top albums for user: \(input.username) (period: \(input.period))")
            
            let result = ResponseFormatters.format(topAlbums)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get top albums for user '\(input.username)': \(error)")
            return ToolResult.failure(error: "Failed to get top albums: \(error.localizedDescription)")
        }
    }
    
    private func executeGetUserTopTags(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetUserTopTagsInput(arguments)
        
        do {
            let topTags = try await lastFMService.getUserTopTags(
                user: input.username,
                limit: input.limit
            )
            
            logger.info("Retrieved \(topTags.results.count) top tags for user: \(input.username)")
            
            let result = ResponseFormatters.format(topTags)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get top tags for user '\(input.username)': \(error)")
            return ToolResult.failure(error: "Failed to get top tags: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Input Parsing Helpers
    
    private func validatePeriod(_ period: String) throws -> String {
        let validPeriods = ["overall", "7day", "1month", "3month", "6month", "12month"]
        guard validPeriods.contains(period) else {
            throw ToolError.invalidParameterType("period", expected: "one of: \(validPeriods.joined(separator: ", "))")
        }
        return period
    }
    
    private func parseGetUserRecentTracksInput(_ arguments: [String: (any Sendable)]) throws -> GetUserRecentTracksInput {
        guard let usernameValue = arguments["username"] else {
            throw ToolError.missingParameter("username")
        }
        
        let username = "\(usernameValue)"
        let limit = try arguments.getValidatedInt(for: "limit", min: 1, max: 200, default: 50) ?? 50
        let page = try arguments.getValidatedInt(for: "page", min: 1, max: Int.max, default: 1) ?? 1
        let extended = arguments.getBool(for: "extended") ?? false
        
        // Parse start_date and end_date timestamps
        var startDate: Date?
        if let startTimestamp = arguments.getInt(for: "start_date") {
            startDate = Date(timeIntervalSince1970: TimeInterval(startTimestamp))
        }
        
        var endDate: Date?
        if let endTimestamp = arguments.getInt(for: "end_date") {
            endDate = Date(timeIntervalSince1970: TimeInterval(endTimestamp))
        }
        
        // Validate that end_date is after start_date if both are provided
        if let start = startDate, let end = endDate, end <= start {
            throw ToolError.invalidParameterType("end_date", expected: "timestamp after start_date")
        }
        
        return GetUserRecentTracksInput(
            username: username,
            limit: limit,
            page: page,
            startDate: startDate,
            extended: extended,
            endDate: endDate
        )
    }
    
    private func parseGetUserTopArtistsInput(_ arguments: [String: (any Sendable)]) throws -> GetUserTopArtistsInput {
        guard let usernameValue = arguments["username"] else {
            throw ToolError.missingParameter("username")
        }
        
        let username = "\(usernameValue)"
        let periodInput = arguments.getString(for: "period") ?? "overall"
        let period = try validatePeriod(periodInput)
        let limit = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000, default: 10) ?? 10
        let page = try arguments.getValidatedInt(for: "page", min: 1, max: Int.max, default: 1) ?? 1
        
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
        let periodInput = arguments.getString(for: "period") ?? "overall"
        let period = try validatePeriod(periodInput)
        let limit = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000, default: 10) ?? 10
        let page = try arguments.getValidatedInt(for: "page", min: 1, max: Int.max, default: 1) ?? 1
        
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
    
    private func parseGetUserFriendsInput(_ arguments: [String: (any Sendable)]) throws -> GetUserFriendsInput {
        guard let usernameValue = arguments["username"] else {
            throw ToolError.missingParameter("username")
        }
        
        let username = "\(usernameValue)"
        let recentTracks = arguments.getBool(for: "recent_tracks") ?? false
        let limit = try arguments.getValidatedInt(for: "limit", min: 1, max: 50, default: 50) ?? 50
        let page = try arguments.getValidatedInt(for: "page", min: 1, max: Int.max, default: 1) ?? 1
        
        return GetUserFriendsInput(
            username: username,
            recentTracks: recentTracks,
            limit: limit,
            page: page
        )
    }
    
    private func parseGetUserLovedTracksInput(_ arguments: [String: (any Sendable)]) throws -> GetUserLovedTracksInput {
        guard let usernameValue = arguments["username"] else {
            throw ToolError.missingParameter("username")
        }
        
        let username = "\(usernameValue)"
        let limit = try arguments.getValidatedInt(for: "limit", min: 1, max: 50, default: 50) ?? 50
        let page = try arguments.getValidatedInt(for: "page", min: 1, max: Int.max, default: 1) ?? 1
        
        return GetUserLovedTracksInput(
            username: username,
            limit: limit,
            page: page
        )
    }
    
    private func parseGetUserPersonalTagsForArtistsInput(_ arguments: [String: (any Sendable)]) throws -> GetUserPersonalTagsForArtistsInput {
        guard let usernameValue = arguments["username"] else {
            throw ToolError.missingParameter("username")
        }
        
        guard let tagValue = arguments["tag"] else {
            throw ToolError.missingParameter("tag")
        }
        
        let username = "\(usernameValue)"
        let tag = "\(tagValue)"
        let limit = try arguments.getValidatedInt(for: "limit", min: 1, max: 50, default: 50) ?? 50
        let page = try arguments.getValidatedInt(for: "page", min: 1, max: Int.max, default: 1) ?? 1
        
        return GetUserPersonalTagsForArtistsInput(
            username: username,
            tag: tag,
            limit: limit,
            page: page
        )
    }
    
    private func parseGetUserTopAlbumsInput(_ arguments: [String: (any Sendable)]) throws -> GetUserTopAlbumsInput {
        guard let usernameValue = arguments["username"] else {
            throw ToolError.missingParameter("username")
        }
        
        let username = "\(usernameValue)"
        let periodInput = arguments.getString(for: "period") ?? "overall"
        let period = try validatePeriod(periodInput)
        let limit = try arguments.getValidatedInt(for: "limit", min: 1, max: 50, default: 50) ?? 50
        let page = try arguments.getValidatedInt(for: "page", min: 1, max: Int.max, default: 1) ?? 1
        
        return GetUserTopAlbumsInput(
            username: username,
            period: period,
            limit: limit,
            page: page
        )
    }
    
    private func parseGetUserTopTagsInput(_ arguments: [String: (any Sendable)]) throws -> GetUserTopTagsInput {
        guard let usernameValue = arguments["username"] else {
            throw ToolError.missingParameter("username")
        }
        
        let username = "\(usernameValue)"
        let limit = arguments.getInt(for: "limit") // Optional, can be nil
        
        return GetUserTopTagsInput(
            username: username,
            limit: limit
        )
    }
}
