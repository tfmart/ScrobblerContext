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
            name: ToolName.scrobbleTrack.rawValue,
            description: ToolName.scrobbleTrack.description,
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
                    "timestamp": .object([
                        "type": .string("integer"),
                        "description": .string("Unix timestamp when the track was played (optional, defaults to current time)")
                    ]),
                    "album": .object([
                        "type": .string("string"),
                        "description": .string("Name of the album (optional but recommended)")
                    ]),
                    "album_artist": .object([
                        "type": .string("string"),
                        "description": .string("Name of the album artist if different from track artist (optional)")
                    ]),
                    "track_number": .object([
                        "type": .string("integer"),
                        "description": .string("Track number on the album (optional)")
                    ]),
                    "duration": .object([
                        "type": .string("integer"),
                        "description": .string("Length of the track in seconds (optional)")
                    ]),
                    "chosen_by_user": .object([
                        "type": .string("boolean"),
                        "description": .string("Whether the track was chosen by the user or was automatically played (optional)")
                    ]),
                    "mbid": .object([
                        "type": .string("string"),
                        "description": .string("MusicBrainz ID for the track (optional)")
                    ])
                ]),
                "required": .array([.string("artist"), .string("track")])
            ])
        )
    }
    
    private static func createUpdateNowPlayingTool() -> Tool {
        return Tool(
            name: ToolName.updateNowPlaying.rawValue,
            description: ToolName.updateNowPlaying.description,
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
                    "track_number": .object([
                        "type": .string("integer"),
                        "description": .string("Track number on the album (optional)")
                    ]),
                    "context": .object([
                        "type": .string("string"),
                        "description": .string("Sub-client context for the playing track (optional)")
                    ]),
                    "mbid": .object([
                        "type": .string("string"),
                        "description": .string("MusicBrainz ID for the track (optional)")
                    ]),
                    "duration": .object([
                        "type": .string("integer"),
                        "description": .string("Length of the track in seconds (optional)")
                    ]),
                    "album_artist": .object([
                        "type": .string("string"),
                        "description": .string("Name of the album artist if different from track artist (optional)")
                    ])
                ]),
                "required": .array([.string("artist"), .string("track")])
            ])
        )
    }
    
    private static func createLoveTrackTool() -> Tool {
        return Tool(
            name: ToolName.loveTrack.rawValue,
            description: ToolName.loveTrack.description,
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
            name: ToolName.unloveTrack.rawValue,
            description: ToolName.unloveTrack.description,
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
    
    func execute(toolName: ToolName, arguments: [String: (any Sendable)]) async throws -> ToolResult {
        logger.info("Executing scrobble tool: \(toolName.rawValue)")
        
        switch toolName {
        case .scrobbleTrack:
            return try await executeScrobbleTrack(arguments: arguments)
        case .updateNowPlaying:
            return try await executeUpdateNowPlaying(arguments: arguments)
        case .loveTrack:
            return try await executeLoveTrack(arguments: arguments)
        case .unloveTrack:
            return try await executeUnloveTrack(arguments: arguments)
        default:
            throw ToolError.lastFMError("Invalid scrobble tool: \(toolName.rawValue)")
        }
    }
    
    // MARK: - Individual Tool Implementations
    
    private func executeScrobbleTrack(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseScrobbleTrackInput(arguments)
        
        do {
            let success = try await lastFMService.scrobbleTrack(
                artist: input.artist,
                track: input.track,
                timestamp: input.timestamp,
                album: input.album,
                albumArtist: input.albumArtist,
                trackNumber: input.trackNumber,
                duration: input.duration,
                chosenByUser: input.chosenByUser,
                mbid: input.mbid
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
                album: input.album,
                trackNumber: input.trackNumber,
                context: input.context,
                mbid: input.mbid,
                duration: input.duration,
                albumArtist: input.albumArtist
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
        
        // Parse timestamp and convert to Date
        var timestamp: Date?
        if let timestampValue = arguments.getInt(for: "timestamp") {
            timestamp = Date(timeIntervalSince1970: TimeInterval(timestampValue))
        }
        
        let album = arguments.getString(for: "album")
        let albumArtist = arguments.getString(for: "album_artist")
        let trackNumber = arguments.getInt(for: "track_number")
        let duration = arguments.getInt(for: "duration")
        let chosenByUser = arguments.getBool(for: "chosen_by_user")
        let mbid = arguments.getString(for: "mbid")
        
        return ScrobbleTrackInput(
            artist: artist,
            track: track,
            timestamp: timestamp,
            album: album,
            albumArtist: albumArtist,
            trackNumber: trackNumber,
            duration: duration,
            chosenByUser: chosenByUser,
            mbid: mbid
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
        let trackNumber = arguments.getInt(for: "track_number")
        let context = arguments.getString(for: "context")
        let mbid = arguments.getString(for: "mbid")
        let duration = arguments.getInt(for: "duration")
        let albumArtist = arguments.getString(for: "album_artist")
        
        return UpdateNowPlayingInput(
            artist: artist,
            track: track,
            album: album,
            trackNumber: trackNumber,
            context: context,
            mbid: mbid,
            duration: duration,
            albumArtist: albumArtist
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
