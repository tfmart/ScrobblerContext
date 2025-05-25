//
//  ScrobbleTools.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 24/05/25.
//

import Foundation
import MCP
@preconcurrency import ScrobbleKit
import Logging

/// Scrobbling and now playing tools for the Last.fm MCP Server
struct ScrobbleTools {
    private let lastFMService: LastFMService
    private let logger = Logger(label: "com.lastfm.mcp-server.scrobble")
    
    init(lastFMService: LastFMService) {
        self.lastFMService = lastFMService
    }
    
    // MARK: - Tool Definitions
    
    static func createTools() -> [Tool] {
        return [
            createScrobbleTrackTool(),
            createUpdateNowPlayingTool(),
            createLoveTrackTool(),
            createUnloveTrackTool()
        ]
    }
    
    private static func createScrobbleTrackTool() -> Tool {
        return Tool(
            name: "scrobble_track",
            description: "Scrobble a track to the authenticated user's Last.fm profile (requires authentication)",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "artist": .object([
                        "type": .string("string"),
                        "description": .string("Name of the artist who performed the track")
                    ]),
                    "track": .object([
                        "type": .string("string"),
                        "description": .string("Name of the track to scrobble")
                    ]),
                    "album": .object([
                        "type": .string("string"),
                        "description": .string("Name of the album (optional but recommended)")
                    ]),
                    "timestamp": .object([
                        "type": .string("integer"),
                        "description": .string("Unix timestamp when the track was played (optional, defaults to current time)")
                    ]),
                    "duration": .object([
                        "type": .string("integer"),
                        "description": .string("Length of the track in seconds (optional)")
                    ])
                ]),
                "required": .array([.string("artist"), .string("track")])
            ])
        )
    }
    
    private static func createUpdateNowPlayingTool() -> Tool {
        return Tool(
            name: "update_now_playing",
            description: "Update the currently playing track for the authenticated user (requires authentication)",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "artist": .object([
                        "type": .string("string"),
                        "description": .string("Name of the artist currently playing")
                    ]),
                    "track": .object([
                        "type": .string("string"),
                        "description": .string("Name of the track currently playing")
                    ]),
                    "album": .object([
                        "type": .string("string"),
                        "description": .string("Name of the album currently playing (optional)")
                    ]),
                    "duration": .object([
                        "type": .string("integer"),
                        "description": .string("Length of the track in seconds (optional)")
                    ]),
                    "track_number": .object([
                        "type": .string("integer"),
                        "description": .string("Track number on the album (optional)")
                    ])
                ]),
                "required": .array([.string("artist"), .string("track")])
            ])
        )
    }
    
    private static func createLoveTrackTool() -> Tool {
        return Tool(
            name: "love_track",
            description: "Mark a track as loved for the authenticated user (requires authentication)",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "artist": .object([
                        "type": .string("string"),
                        "description": .string("Name of the artist who performed the track")
                    ]),
                    "track": .object([
                        "type": .string("string"),
                        "description": .string("Name of the track to love")
                    ])
                ]),
                "required": .array([.string("artist"), .string("track")])
            ])
        )
    }
    
    private static func createUnloveTrackTool() -> Tool {
        return Tool(
            name: "unlove_track",
            description: "Remove a track from the authenticated user's loved tracks (requires authentication)",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "artist": .object([
                        "type": .string("string"),
                        "description": .string("Name of the artist who performed the track")
                    ]),
                    "track": .object([
                        "type": .string("string"),
                        "description": .string("Name of the track to unlove")
                    ])
                ]),
                "required": .array([.string("artist"), .string("track")])
            ])
        )
    }
    
    // MARK: - Tool Execution
    
    func execute(toolName: String, arguments: [String: (any Sendable)]) async throws -> ToolResult {
        logger.info("Executing scrobble tool: \(toolName)")
        
        switch toolName {
        case "scrobble_track":
            return try await executeScrobbleTrack(arguments: arguments)
        case "update_now_playing":
            return try await executeUpdateNowPlaying(arguments: arguments)
        case "love_track":
            return try await executeLoveTrack(arguments: arguments)
        case "unlove_track":
            return try await executeUnloveTrack(arguments: arguments)
        default:
            throw ToolError.lastFMError("Unknown scrobble tool: \(toolName)")
        }
    }
    
    // MARK: - Individual Tool Implementations
    
    private func executeScrobbleTrack(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseScrobbleTrackInput(arguments)
        
        do {
            let success = try await lastFMService.scrobbleTrack(
                artist: input.artist,
                track: input.track,
                album: input.album
            )
            
            if success {
                logger.info("Successfully scrobbled: '\(input.track)' by '\(input.artist)'")
            } else {
                logger.warning("Scrobble partially failed for: '\(input.track)' by '\(input.artist)'")
            }
            
            let result = ResponseFormatters.formatScrobbleResult(
                success: success,
                artist: input.artist,
                track: input.track,
                album: input.album
            )
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to scrobble '\(input.track)' by '\(input.artist)': \(error)")
            return ToolResult.failure(error: "Scrobble failed: \(error.localizedDescription)")
        }
    }
    
    private func executeUpdateNowPlaying(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseUpdateNowPlayingInput(arguments)
        
        do {
            let success = try await lastFMService.updateNowPlaying(
                artist: input.artist,
                track: input.track,
                album: input.album
            )
            
            logger.info("Successfully updated now playing: '\(input.track)' by '\(input.artist)'")
            
            let result = ResponseFormatters.formatNowPlayingResult(
                success: success,
                artist: input.artist,
                track: input.track,
                album: input.album
            )
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to update now playing for '\(input.track)' by '\(input.artist)': \(error)")
            return ToolResult.failure(error: "Update now playing failed: \(error.localizedDescription)")
        }
    }
    
    private func executeLoveTrack(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseLoveTrackInput(arguments)
        
        do {
            try await lastFMService.loveTrack(track: input.track, artist: input.artist)
            
            logger.info("Successfully loved track: '\(input.track)' by '\(input.artist)'")
            
            let result = ResponseFormatters.formatLoveResult(
                loved: true,
                artist: input.artist,
                track: input.track
            )
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to love track '\(input.track)' by '\(input.artist)': \(error)")
            return ToolResult.failure(error: "Love track failed: \(error.localizedDescription)")
        }
    }
    
    private func executeUnloveTrack(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseUnloveTrackInput(arguments)
        
        do {
            try await lastFMService.unloveTrack(track: input.track, artist: input.artist)
            
            logger.info("Successfully unloved track: '\(input.track)' by '\(input.artist)'")
            
            let result = ResponseFormatters.formatLoveResult(
                loved: false,
                artist: input.artist,
                track: input.track
            )
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to unlove track '\(input.track)' by '\(input.artist)': \(error)")
            return ToolResult.failure(error: "Unlove track failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Input Parsing Helpers
    
    private func parseScrobbleTrackInput(_ arguments: [String: (any Sendable)]) throws -> ScrobbleTrackInput {
        guard let artistValue = arguments["artist"] else {
            throw ToolError.missingParameter("artist")
        }
        
        guard let trackValue = arguments["track"] else {
            throw ToolError.missingParameter("track")
        }
        
        let artist = "\(artistValue)"
        let track = "\(trackValue)"
        let album = arguments.getString(for: "album")
        let timestamp = arguments.getInt(for: "timestamp")
        let duration = arguments.getInt(for: "duration")
        
        return ScrobbleTrackInput(
            artist: artist,
            track: track,
            album: album
        )
    }
    
    private func parseUpdateNowPlayingInput(_ arguments: [String: (any Sendable)]) throws -> UpdateNowPlayingInput {
        guard let artistValue = arguments["artist"] else {
            throw ToolError.missingParameter("artist")
        }
        
        guard let trackValue = arguments["track"] else {
            throw ToolError.missingParameter("track")
        }
        
        let artist = "\(artistValue)"
        let track = "\(trackValue)"
        let album = arguments.getString(for: "album")
        let duration = arguments.getInt(for: "duration")
        let trackNumber = arguments.getInt(for: "track_number")
        
        return UpdateNowPlayingInput(
            artist: artist,
            track: track,
            album: album,
            duration: duration,
            trackNumber: trackNumber
        )
    }
    
    private func parseLoveTrackInput(_ arguments: [String: (any Sendable)]) throws -> LoveTrackInput {
        guard let artistValue = arguments["artist"] else {
            throw ToolError.missingParameter("artist")
        }
        
        guard let trackValue = arguments["track"] else {
            throw ToolError.missingParameter("track")
        }
        
        let artist = "\(artistValue)"
        let track = "\(trackValue)"
        
        return LoveTrackInput(artist: artist, track: track)
    }
    
    private func parseUnloveTrackInput(_ arguments: [String: (any Sendable)]) throws -> UnloveTrackInput {
        guard let artistValue = arguments["artist"] else {
            throw ToolError.missingParameter("artist")
        }
        
        guard let trackValue = arguments["track"] else {
            throw ToolError.missingParameter("track")
        }
        
        let artist = "\(artistValue)"
        let track = "\(trackValue)"
        
        return UnloveTrackInput(artist: artist, track: track)
    }
}

// MARK: - Input Models for Scrobble Tools

struct UpdateNowPlayingInput: ToolInput {
    let artist: String
    let track: String
    let album: String?
    let duration: Int?
    let trackNumber: Int?
    
    static let requiredParameters = ["artist", "track"]
    static let optionalParameters: [String: (any Sendable)] = [
        "album": "",
        "duration": 0,
        "track_number": 0
    ]
}

struct LoveTrackInput: ToolInput {
    let artist: String
    let track: String
    
    static let requiredParameters = ["artist", "track"]
    static let optionalParameters: [String: (any Sendable)] = [:]
}

struct UnloveTrackInput: ToolInput {
    let artist: String
    let track: String
    
    static let requiredParameters = ["artist", "track"]
    static let optionalParameters: [String: (any Sendable)] = [:]
}
