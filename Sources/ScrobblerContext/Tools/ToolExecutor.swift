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
    
    /// Get all available tools
    func getAvailableTools() -> [Tool] {
        return toolRegistry.getAllTools()
    }
    
    /// Execute a tool with the given arguments
    func execute(toolName: String, arguments: [String: (any Sendable)]?) async throws -> CallTool.Result {
        let startTime = Date()
        logger.info("Executing tool: \(toolName)")
        
        do {
            let result = try await toolRegistry.executeTool(
                name: toolName,
                arguments: arguments ?? [:]
            )
            
            let executionTime = Date().timeIntervalSince(startTime)
            logger.info("Tool \(toolName) completed successfully in \(String(format: "%.3f", executionTime))s")
            
            let jsonString = try result.toJSON()
            return CallTool.Result(content: [
                .text(jsonString)
            ])
            
        } catch {
            let executionTime = Date().timeIntervalSince(startTime)
            logger.error("Tool \(toolName) failed after \(String(format: "%.3f", executionTime))s: \(error)")
            
            let errorResult = ToolResult.failure(error: error.localizedDescription)
            let jsonString = try errorResult.toJSON()
            
            return CallTool.Result(content: [
                .text(jsonString)
            ])
        }
    }
    
    // MARK: - Validation Methods
    
    /// Validate tool arguments before execution
    func validateToolArguments(toolName: String, arguments: [String: (any Sendable)]) throws {
        guard let tool = ToolName(rawValue: toolName) else {
            throw ToolError.lastFMError("Unknown tool: \(toolName)")
        }
        
        try validateToolArguments(tool: tool, arguments: arguments)
    }
    
    /// Validate tool arguments using ToolName enum
    func validateToolArguments(tool: ToolName, arguments: [String: (any Sendable)]) throws {
        switch tool {
        // MARK: - Authentication Tools
        case .authenticateBrowser:
            try validateBrowserAuthArguments(arguments)
            
        case .setSessionKey:
            try validateSetSessionKeyArguments(arguments)
            
        case .checkAuthStatus, .logout:
            // These tools don't require arguments
            break
            
        // MARK: - Artist Tools
        case .searchArtist:
            try validateSearchArtistArguments(arguments)
            
        case .getArtistInfo:
            try validateGetArtistInfoArguments(arguments)
            
        case .getSimilarArtists:
            try validateGetSimilarArtistsArguments(arguments)
            
        case .addArtistTags:
            try validateAddArtistTagsArguments(arguments)
            
        case .getArtistCorrection:
            try validateGetArtistCorrectionArguments(arguments)
            
        case .getArtistTags:
            try validateGetArtistTagsArguments(arguments)
            
        case .getArtistTopAlbums:
            try validateGetArtistTopAlbumsArguments(arguments)
            
        case .getArtistTopTracks:
            try validateGetArtistTopTracksArguments(arguments)
            
        case .removeArtistTag:
            try validateRemoveArtistTagArguments(arguments)
            
        // MARK: - Album Tools
        case .searchAlbum:
            try validateSearchAlbumArguments(arguments)
            
        case .getAlbumInfo:
            try validateGetAlbumInfoArguments(arguments)
            
        case .addAlbumTags:
            try validateAddAlbumTagsArguments(arguments)
            
        case .getAlbumTags:
            try validateGetAlbumTagsArguments(arguments)
            
        case .getAlbumTopTags:
            try validateGetAlbumTopTagsArguments(arguments)
            
        case .removeAlbumTag:
            try validateRemoveAlbumTagArguments(arguments)
            
        // MARK: - Track Tools
        case .searchTrack:
            try validateSearchTrackArguments(arguments)
            
        case .getTrackInfo:
            try validateGetTrackInfoArguments(arguments)
            
        case .getSimilarTracks:
            try validateGetSimilarTracksArguments(arguments)
            
        case .getTrackCorrection:
            try validateGetTrackCorrectionArguments(arguments)
            
        case .getTrackTags:
            try validateGetTrackTagsArguments(arguments)
            
        case .getTrackTopTags:
            try validateGetTrackTopTagsArguments(arguments)
            
        case .addTrackTags:
            try validateAddTrackTagsArguments(arguments)
            
        case .removeTrackTag:
            try validateRemoveTrackTagArguments(arguments)
            
        // MARK: - User Tools
        case .getUserRecentTracks:
            try validateGetUserRecentTracksArguments(arguments)
            
        case .getUserTopArtists:
            try validateGetUserTopArtistsArguments(arguments)
            
        case .getUserTopTracks:
            try validateGetUserTopTracksArguments(arguments)
            
        case .getUserInfo:
            try validateGetUserInfoArguments(arguments)
            
        case .getUserFriends:
            try validateGetUserFriendsArguments(arguments)
            
        case .getUserLovedTracks:
            try validateGetUserLovedTracksArguments(arguments)
            
        case .getUserPersonalTagsForArtists:
            try validateGetUserPersonalTagsForArtistsArguments(arguments)
            
        case .getUserTopAlbums:
            try validateGetUserTopAlbumsArguments(arguments)
            
        case .getUserTopTags:
            try validateGetUserTopTagsArguments(arguments)
            
        // MARK: - Scrobble Tools
        case .scrobbleTrack:
            try validateScrobbleTrackArguments(arguments)
            
        case .scrobbleMultipleTracks:
            try validateScrobbleMultipleTracksArguments(arguments)
            
        case .updateNowPlaying:
            try validateUpdateNowPlayingArguments(arguments)
            
        case .loveTrack:
            try validateLoveTrackArguments(arguments)
            
        case .unloveTrack:
            try validateUnloveTrackArguments(arguments)
        }
    }
    
    // MARK: - Authentication Validation Methods
    
    private func validateBrowserAuthArguments(_ arguments: [String: (any Sendable)]) throws {
        // Port validation (optional)
        if let _ = arguments["port"] {
            _ = try arguments.getValidatedInt(for: "port", min: 1024, max: 65535)
        }
        
        // auto_open validation (optional boolean)
        if let _ = arguments["auto_open"] {
            _ = arguments.getBool(for: "auto_open")
        }
    }
    
    private func validateSetSessionKeyArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let sessionKey = arguments.getString(for: "session_key"), !sessionKey.isEmpty else {
            throw ToolError.missingParameter("session_key")
        }
    }
    
    // MARK: - Artist Validation Methods
    
    private func validateSearchArtistArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let query = arguments.getString(for: "query"), !query.isEmpty else {
            throw ToolError.missingParameter("query")
        }
        
        // Optional parameters validation
        if let _ = arguments["limit"] {
            _ = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000)
        }
        
        if let _ = arguments["page"] {
            _ = try arguments.getValidatedInt(for: "page", min: 1)
        }
    }
    
    private func validateGetArtistInfoArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let name = arguments.getString(for: "name"), !name.isEmpty else {
            throw ToolError.missingParameter("name")
        }
    }
    
    private func validateGetSimilarArtistsArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let name = arguments.getString(for: "name"), !name.isEmpty else {
            throw ToolError.missingParameter("name")
        }
        
        if let _ = arguments["limit"] {
            _ = try arguments.getValidatedInt(for: "limit", min: 1, max: 100)
        }
    }
    
    private func validateAddArtistTagsArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
        
        guard let tagsValue = arguments["tags"] else {
            throw ToolError.missingParameter("tags")
        }
        
        // Validate tags array
        guard let tags = tagsValue as? [String], !tags.isEmpty else {
            throw ToolError.invalidParameterType("tags", expected: "non-empty array of strings")
        }
        
        // Validate each tag
        for tag in tags {
            if tag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw ToolError.invalidParameterType("tags", expected: "array of non-empty strings")
            }
        }
    }
    
    private func validateGetArtistCorrectionArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
    }
    
    private func validateGetArtistTagsArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let name = arguments.getString(for: "name"), !name.isEmpty else {
            throw ToolError.missingParameter("name")
        }
    }
    
    private func validateGetArtistTopAlbumsArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let name = arguments.getString(for: "name"), !name.isEmpty else {
            throw ToolError.missingParameter("name")
        }
        
        if let _ = arguments["limit"] {
            _ = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000)
        }
        
        if let _ = arguments["page"] {
            _ = try arguments.getValidatedInt(for: "page", min: 1)
        }
    }
    
    private func validateGetArtistTopTracksArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let name = arguments.getString(for: "name"), !name.isEmpty else {
            throw ToolError.missingParameter("name")
        }
        
        if let _ = arguments["limit"] {
            _ = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000)
        }
        
        if let _ = arguments["page"] {
            _ = try arguments.getValidatedInt(for: "page", min: 1)
        }
    }
    
    private func validateRemoveArtistTagArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
        
        guard let tag = arguments.getString(for: "tag"), !tag.isEmpty else {
            throw ToolError.missingParameter("tag")
        }
    }
    
    // MARK: - Album Validation Methods
    
    private func validateSearchAlbumArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let query = arguments.getString(for: "query"), !query.isEmpty else {
            throw ToolError.missingParameter("query")
        }
        
        if let _ = arguments["limit"] {
            _ = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000)
        }
        
        if let _ = arguments["page"] {
            _ = try arguments.getValidatedInt(for: "page", min: 1)
        }
    }
    
    private func validateGetAlbumInfoArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let album = arguments.getString(for: "album"), !album.isEmpty else {
            throw ToolError.missingParameter("album")
        }
        
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
    }
    
    private func validateAddAlbumTagsArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let album = arguments.getString(for: "album"), !album.isEmpty else {
            throw ToolError.missingParameter("album")
        }
        
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
        
        guard let tagsValue = arguments["tags"] else {
            throw ToolError.missingParameter("tags")
        }
        
        guard let tags = tagsValue as? [String], !tags.isEmpty else {
            throw ToolError.invalidParameterType("tags", expected: "non-empty array of strings")
        }
    }
    
    private func validateGetAlbumTagsArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let album = arguments.getString(for: "album"), !album.isEmpty else {
            throw ToolError.missingParameter("album")
        }
        
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
    }
    
    private func validateGetAlbumTopTagsArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let album = arguments.getString(for: "album"), !album.isEmpty else {
            throw ToolError.missingParameter("album")
        }
        
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
    }
    
    private func validateRemoveAlbumTagArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let album = arguments.getString(for: "album"), !album.isEmpty else {
            throw ToolError.missingParameter("album")
        }
        
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
        
        guard let tag = arguments.getString(for: "tag"), !tag.isEmpty else {
            throw ToolError.missingParameter("tag")
        }
    }
    
    // MARK: - Track Validation Methods
    
    private func validateSearchTrackArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let query = arguments.getString(for: "query"), !query.isEmpty else {
            throw ToolError.missingParameter("query")
        }
        
        if let _ = arguments["limit"] {
            _ = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000)
        }
        
        if let _ = arguments["page"] {
            _ = try arguments.getValidatedInt(for: "page", min: 1)
        }
    }
    
    private func validateGetTrackInfoArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let track = arguments.getString(for: "track"), !track.isEmpty else {
            throw ToolError.missingParameter("track")
        }
        
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
    }
    
    private func validateGetSimilarTracksArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let track = arguments.getString(for: "track"), !track.isEmpty else {
            throw ToolError.missingParameter("track")
        }
        
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
        
        if let _ = arguments["limit"] {
            _ = try arguments.getValidatedInt(for: "limit", min: 1, max: 100)
        }
    }
    
    private func validateGetTrackCorrectionArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let track = arguments.getString(for: "track"), !track.isEmpty else {
            throw ToolError.missingParameter("track")
        }
        
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
    }
    
    private func validateGetTrackTagsArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let track = arguments.getString(for: "track"), !track.isEmpty else {
            throw ToolError.missingParameter("track")
        }
        
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
    }
    
    private func validateGetTrackTopTagsArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let track = arguments.getString(for: "track"), !track.isEmpty else {
            throw ToolError.missingParameter("track")
        }
        
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
    }
    
    private func validateAddTrackTagsArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let track = arguments.getString(for: "track"), !track.isEmpty else {
            throw ToolError.missingParameter("track")
        }
        
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
        
        guard let tagsValue = arguments["tags"] else {
            throw ToolError.missingParameter("tags")
        }
        
        guard let tags = tagsValue as? [String], !tags.isEmpty else {
            throw ToolError.invalidParameterType("tags", expected: "non-empty array of strings")
        }
    }
    
    private func validateRemoveTrackTagArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let track = arguments.getString(for: "track"), !track.isEmpty else {
            throw ToolError.missingParameter("track")
        }
        
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
        
        guard let tag = arguments.getString(for: "tag"), !tag.isEmpty else {
            throw ToolError.missingParameter("tag")
        }
    }
    
    // MARK: - User Validation Methods
    
    private func validateGetUserRecentTracksArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let user = arguments.getString(for: "user"), !user.isEmpty else {
            throw ToolError.missingParameter("user")
        }
        
        if let _ = arguments["limit"] {
            _ = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000)
        }
        
        if let _ = arguments["page"] {
            _ = try arguments.getValidatedInt(for: "page", min: 1)
        }
    }
    
    private func validateGetUserTopArtistsArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let user = arguments.getString(for: "user"), !user.isEmpty else {
            throw ToolError.missingParameter("user")
        }
        
        if let _ = arguments["limit"] {
            _ = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000)
        }
        
        if let _ = arguments["page"] {
            _ = try arguments.getValidatedInt(for: "page", min: 1)
        }
        
        // Validate period if provided
        if let period = arguments.getString(for: "period") {
            let validPeriods = ["7day", "7days", "1month", "3month", "6month", "12month", "overall"]
            if !validPeriods.contains(period.lowercased()) {
                throw ToolError.invalidParameterType("period", expected: "one of: \(validPeriods.joined(separator: ", "))")
            }
        }
    }
    
    private func validateGetUserTopTracksArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let user = arguments.getString(for: "user"), !user.isEmpty else {
            throw ToolError.missingParameter("user")
        }
        
        if let _ = arguments["limit"] {
            _ = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000)
        }
        
        if let _ = arguments["page"] {
            _ = try arguments.getValidatedInt(for: "page", min: 1)
        }
        
        // Validate period if provided
        if let period = arguments.getString(for: "period") {
            let validPeriods = ["7day", "7days", "1month", "3month", "6month", "12month", "overall"]
            if !validPeriods.contains(period.lowercased()) {
                throw ToolError.invalidParameterType("period", expected: "one of: \(validPeriods.joined(separator: ", "))")
            }
        }
    }
    
    private func validateGetUserInfoArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let username = arguments.getString(for: "username"), !username.isEmpty else {
            throw ToolError.missingParameter("username")
        }
    }
    
    private func validateGetUserFriendsArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let user = arguments.getString(for: "user"), !user.isEmpty else {
            throw ToolError.missingParameter("user")
        }
        
        if let _ = arguments["limit"] {
            _ = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000)
        }
        
        if let _ = arguments["page"] {
            _ = try arguments.getValidatedInt(for: "page", min: 1)
        }
    }
    
    private func validateGetUserLovedTracksArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let user = arguments.getString(for: "user"), !user.isEmpty else {
            throw ToolError.missingParameter("user")
        }
        
        if let _ = arguments["limit"] {
            _ = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000)
        }
        
        if let _ = arguments["page"] {
            _ = try arguments.getValidatedInt(for: "page", min: 1)
        }
    }
    
    private func validateGetUserPersonalTagsForArtistsArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let user = arguments.getString(for: "user"), !user.isEmpty else {
            throw ToolError.missingParameter("user")
        }
        
        guard let tag = arguments.getString(for: "tag"), !tag.isEmpty else {
            throw ToolError.missingParameter("tag")
        }
        
        if let _ = arguments["limit"] {
            _ = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000)
        }
        
        if let _ = arguments["page"] {
            _ = try arguments.getValidatedInt(for: "page", min: 1)
        }
    }
    
    private func validateGetUserTopAlbumsArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let user = arguments.getString(for: "user"), !user.isEmpty else {
            throw ToolError.missingParameter("user")
        }
        
        if let _ = arguments["limit"] {
            _ = try arguments.getValidatedInt(for: "limit", min: 1, max: 1000)
        }
        
        if let _ = arguments["page"] {
            _ = try arguments.getValidatedInt(for: "page", min: 1)
        }
        
        // Validate period if provided
        if let period = arguments.getString(for: "period") {
            let validPeriods = ["7day", "7days", "1month", "3month", "6month", "12month", "overall"]
            if !validPeriods.contains(period.lowercased()) {
                throw ToolError.invalidParameterType("period", expected: "one of: \(validPeriods.joined(separator: ", "))")
            }
        }
    }
    
    private func validateGetUserTopTagsArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let user = arguments.getString(for: "user"), !user.isEmpty else {
            throw ToolError.missingParameter("user")
        }
        
        if let _ = arguments["limit"] {
            _ = try arguments.getValidatedInt(for: "limit", min: 1)
        }
    }
    
    // MARK: - Scrobble Validation Methods
    
    private func validateScrobbleTrackArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
        
        guard let track = arguments.getString(for: "track"), !track.isEmpty else {
            throw ToolError.missingParameter("track")
        }
        
        // Optional validations
        if let _ = arguments["track_number"] {
            _ = try arguments.getValidatedInt(for: "track_number", min: 1)
        }
        
        if let _ = arguments["duration"] {
            _ = try arguments.getValidatedInt(for: "duration", min: 1)
        }
    }
    
    private func validateScrobbleMultipleTracksArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let tracksValue = arguments["tracks"] else {
            throw ToolError.missingParameter("tracks")
        }
        
        guard let tracks = tracksValue as? [[String: Any]], !tracks.isEmpty else {
            throw ToolError.invalidParameterType("tracks", expected: "non-empty array of track objects")
        }
        
        // Validate each track object
        for (index, track) in tracks.enumerated() {
            guard let artist = track["artist"] as? String, !artist.isEmpty else {
                throw ToolError.invalidParameterType("tracks[\(index)].artist", expected: "non-empty string")
            }
            
            guard let trackName = track["track"] as? String, !trackName.isEmpty else {
                throw ToolError.invalidParameterType("tracks[\(index)].track", expected: "non-empty string")
            }
        }
    }
    
    private func validateUpdateNowPlayingArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
        
        guard let track = arguments.getString(for: "track"), !track.isEmpty else {
            throw ToolError.missingParameter("track")
        }
        
        // Optional validations
        if let _ = arguments["track_number"] {
            _ = try arguments.getValidatedInt(for: "track_number", min: 1)
        }
        
        if let _ = arguments["duration"] {
            _ = try arguments.getValidatedInt(for: "duration", min: 1)
        }
    }
    
    private func validateLoveTrackArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
        
        guard let track = arguments.getString(for: "track"), !track.isEmpty else {
            throw ToolError.missingParameter("track")
        }
    }
    
    private func validateUnloveTrackArguments(_ arguments: [String: (any Sendable)]) throws {
        guard let artist = arguments.getString(for: "artist"), !artist.isEmpty else {
            throw ToolError.missingParameter("artist")
        }
        
        guard let track = arguments.getString(for: "track"), !track.isEmpty else {
            throw ToolError.missingParameter("track")
        }
    }
}
