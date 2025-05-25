//
//  TrackTools.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 17/05/25.
//

import Foundation
import MCP
@preconcurrency import ScrobbleKit
import Logging

/// Track-related tools for the Last.fm MCP Server
struct TrackTools {
    private let lastFMService: LastFMService
    private let logger = Logger(label: "com.lastfm.mcp-server.track")
    
    init(lastFMService: LastFMService) {
        self.lastFMService = lastFMService
    }
    
    // MARK: - Tool Definitions
    
    static func createTools() -> [Tool] {
        return [
            createSearchTrackTool(),
            createGetTrackInfoTool(),
            createGetSimilarTracksTool()
        ]
    }
    
    private static func createSearchTrackTool() -> Tool {
        return Tool(
            name: ToolName.searchTrack.rawValue,
            description: ToolName.searchTrack.description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "query": .object([
                        "type": .string("string"),
                        "description": .string("Track name to search for")
                    ]),
                    "artist": .object([
                        "type": .string("string"),
                        "description": .string("Artist name to filter results (optional but recommended for better accuracy)")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Maximum number of results (1-50)"),
                        "default": .int(10),
                        "minimum": .int(1),
                        "maximum": .int(50)
                    ])
                ]),
                "required": .array([.string("query")])
            ])
        )
    }
    
    private static func createGetTrackInfoTool() -> Tool {
        return Tool(
            name: ToolName.getTrackInfo.rawValue,
            description: ToolName.getTrackInfo.description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "track": .object([
                        "type": .string("string"),
                        "description": .string("Name of the track")
                    ]),
                    "artist": .object([
                        "type": .string("string"),
                        "description": .string("Name of the artist who performed the track")
                    ]),
                    "autocorrect": .object([
                        "type": .string("boolean"),
                        "description": .string("Automatically correct misspelled track/artist names"),
                        "default": .bool(true)
                    ]),
                    "username": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username for personalized data (e.g., user's playcount, loved status)")
                    ])
                ]),
                "required": .array([.string("track"), .string("artist")])
            ])
        )
    }
    
    private static func createGetSimilarTracksTool() -> Tool {
        return Tool(
            name: ToolName.getSimilarTracks.rawValue,
            description: ToolName.getSimilarTracks.description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "track": .object([
                        "type": .string("string"),
                        "description": .string("Name of the track to find similar tracks for")
                    ]),
                    "artist": .object([
                        "type": .string("string"),
                        "description": .string("Name of the artist who performed the track")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Maximum number of similar tracks to return (1-50)"),
                        "default": .int(10),
                        "minimum": .int(1),
                        "maximum": .int(50)
                    ]),
                    "autocorrect": .object([
                        "type": .string("boolean"),
                        "description": .string("Automatically correct misspelled track/artist names"),
                        "default": .bool(true)
                    ])
                ]),
                "required": .array([.string("track"), .string("artist")])
            ])
        )
    }
    
    // MARK: - Tool Execution
    
    func execute(toolName: ToolName, arguments: [String: (any Sendable)]) async throws -> ToolResult {
        logger.info("Executing track tool: \(toolName.rawValue)")
        
        switch toolName {
        case .searchTrack:
            return try await executeSearchTrack(arguments: arguments)
        case .getTrackInfo:
            return try await executeGetTrackInfo(arguments: arguments)
        case .getSimilarTracks:
            return try await executeGetSimilarTracks(arguments: arguments)
        default:
            throw ToolError.lastFMError("Invalid track tool: \(toolName.rawValue)")
        }
    }
    
    // MARK: - Individual Tool Implementations
    
    private func executeSearchTrack(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseSearchTrackInput(arguments)
        
        do {
            let tracks = try await lastFMService.searchTrack(
                query: input.query,
                artist: input.artist,
                limit: input.limit
            )
            
            if let artist = input.artist {
                logger.info("Found \(tracks.count) tracks for query: '\(input.query)' by '\(artist)'")
            } else {
                logger.info("Found \(tracks.count) tracks for query: '\(input.query)'")
            }
            
            let result = ResponseFormatters.format(tracks)
            return ToolResult.success(data: result)
            
        } catch {
            let errorContext = input.artist != nil ? "'\(input.query)' by '\(input.artist!)'" : "'\(input.query)'"
            logger.error("Track search failed for \(errorContext): \(error)")
            return ToolResult.failure(error: "Track search failed: \(error.localizedDescription)")
        }
    }
    
    private func executeGetTrackInfo(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetTrackInfoInput(arguments)
        
        do {
            let track = try await lastFMService.getTrackInfo(
                track: input.track,
                artist: input.artist
            )
            
            logger.info("Retrieved track info for: '\(input.track)' by '\(input.artist)'")
            
            let result = ResponseFormatters.format(track)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get track info for '\(input.track)' by '\(input.artist)': \(error)")
            return ToolResult.failure(error: "Failed to get track info: \(error.localizedDescription)")
        }
    }
    
    private func executeGetSimilarTracks(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetSimilarTracksInput(arguments)
        
        do {
            // Note: We'll need to extend LastFMService to support getSimilarTracks
            // For now, let's add this method to the service
            let similarTracks = try await lastFMService.getSimilarTracks(
                track: input.track,
                artist: input.artist,
                limit: input.limit
            )
            
            logger.info("Found \(similarTracks.count) similar tracks for: '\(input.track)' by '\(input.artist)'")
            
            let result = ResponseFormatters.formatSimilarTracks(similarTracks)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get similar tracks for '\(input.track)' by '\(input.artist)': \(error)")
            return ToolResult.failure(error: "Failed to get similar tracks: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Input Parsing Helpers
    
    private func parseSearchTrackInput(_ arguments: [String: (any Sendable)]) throws -> SearchTrackInput {
        guard let queryValue = arguments["query"] else {
            throw ToolError.missingParameter("query")
        }
        
        let query = "\(queryValue)"
        let artist = arguments.getString(for: "artist")
        let limit = try arguments.getValidatedInt(for: "limit", min: 1, max: 50, default: 10) ?? 10
        
        return SearchTrackInput(
            query: query,
            artist: artist,
            limit: limit
        )
    }
    
    private func parseGetTrackInfoInput(_ arguments: [String: (any Sendable)]) throws -> GetTrackInfoInput {
        guard let trackValue = arguments["track"] else {
            throw ToolError.missingParameter("track")
        }
        
        guard let artistValue = arguments["artist"] else {
            throw ToolError.missingParameter("artist")
        }
        
        let track = "\(trackValue)"
        let artist = "\(artistValue)"
        let autocorrect = arguments.getBool(for: "autocorrect") ?? true
        let username = arguments.getString(for: "username")
        
        return GetTrackInfoInput(
            track: track,
            artist: artist,
            autocorrect: autocorrect,
            username: username
        )
    }
    
    private func parseGetSimilarTracksInput(_ arguments: [String: (any Sendable)]) throws -> GetSimilarTracksInput {
        guard let trackValue = arguments["track"] else {
            throw ToolError.missingParameter("track")
        }
        
        guard let artistValue = arguments["artist"] else {
            throw ToolError.missingParameter("artist")
        }
        
        let track = "\(trackValue)"
        let artist = "\(artistValue)"
        let autocorrect = arguments.getBool(for: "autocorrect") ?? true
        let limit = try arguments.getValidatedInt(for: "limit", min: 1, max: 50, default: 10) ?? 10
        
        return GetSimilarTracksInput(
            track: track,
            artist: artist,
            limit: limit,
            autocorrect: autocorrect
        )
    }
}

// MARK: - Input Models for Track Tools

struct GetTrackInfoInput: ToolInput {
    let track: String
    let artist: String
    let autocorrect: Bool
    let username: String?
    
    static let requiredParameters = ["track", "artist"]
    static let optionalParameters: [String: (any Sendable)] = [
        "autocorrect": true,
        "username": ""
    ]
}

struct GetSimilarTracksInput: ToolInput {
    let track: String
    let artist: String
    let limit: Int
    let autocorrect: Bool
    
    static let requiredParameters = ["track", "artist"]
    static let optionalParameters: [String: (any Sendable)] = [
        "limit": 10,
        "autocorrect": true
    ]
}
