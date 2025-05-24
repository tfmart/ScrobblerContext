//
//  AlbumTools.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 24/05/25.
//


//
//  AlbumTools.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 17/05/25.
//

import Foundation
import MCP
@preconcurrency import ScrobbleKit
import Logging

/// Album-related tools for the Last.fm MCP Server
struct AlbumTools {
    private let lastFMService: LastFMService
    private let logger = Logger(label: "com.lastfm.mcp-server.album")
    
    init(lastFMService: LastFMService) {
        self.lastFMService = lastFMService
    }
    
    // MARK: - Tool Definitions
    
    static func createTools() -> [Tool] {
        return [
            createSearchAlbumTool(),
            createGetAlbumInfoTool()
        ]
    }
    
    private static func createSearchAlbumTool() -> Tool {
        return Tool(
            name: "search_album",
            description: "Search for albums on Last.fm by name",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "query": .object([
                        "type": .string("string"),
                        "description": .string("Album name to search for")
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
    
    private static func createGetAlbumInfoTool() -> Tool {
        return Tool(
            name: "get_album_info",
            description: "Get detailed information about a specific album including tracklist, tags, and stats",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "album": .object([
                        "type": .string("string"),
                        "description": .string("Name of the album")
                    ]),
                    "artist": .object([
                        "type": .string("string"),
                        "description": .string("Name of the artist who created the album")
                    ]),
                    "autocorrect": .object([
                        "type": .string("boolean"),
                        "description": .string("Automatically correct misspelled album/artist names"),
                        "default": .bool(true)
                    ]),
                    "username": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username for personalized data (e.g., user's playcount)")
                    ]),
                    "language": .object([
                        "type": .string("string"),
                        "description": .string("Language for album information (ISO 639-1 code, e.g., 'en', 'es', 'fr')"),
                        "default": .string("en")
                    ])
                ]),
                "required": .array([.string("album"), .string("artist")])
            ])
        )
    }
    
    // MARK: - Tool Execution
    
    func execute(toolName: String, arguments: [String: Any]) async throws -> ToolResult {
        logger.info("Executing album tool: \(toolName)")
        
        switch toolName {
        case "search_album":
            return try await executeSearchAlbum(arguments: arguments)
        case "get_album_info":
            return try await executeGetAlbumInfo(arguments: arguments)
        default:
            throw ToolError.lastFMError("Unknown album tool: \(toolName)")
        }
    }
    
    // MARK: - Individual Tool Implementations
    
    private func executeSearchAlbum(arguments: [String: Any]) async throws -> ToolResult {
        let input = try parseSearchAlbumInput(arguments)
        
        do {
            let albums = try await lastFMService.searchAlbum(
                query: input.query,
                limit: input.limit
            )
            
            logger.info("Found \(albums.count) albums for query: \(input.query)")
            
            let result = ResponseFormatters.format(albums)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Album search failed for query '\(input.query)': \(error)")
            return ToolResult.failure(error: "Album search failed: \(error.localizedDescription)")
        }
    }
    
    private func executeGetAlbumInfo(arguments: [String: Any]) async throws -> ToolResult {
        let input = try parseGetAlbumInfoInput(arguments)
        
        do {
            // For now, we'll use the basic getAlbumInfo method
            // In the future, we can extend LastFMService to support additional parameters
            let album = try await lastFMService.getAlbumInfo(
                album: input.album,
                artist: input.artist
            )
            
            logger.info("Retrieved album info for: '\(input.album)' by \(input.artist)")
            
            let result = ResponseFormatters.format(album)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get album info for '\(input.album)' by '\(input.artist)': \(error)")
            return ToolResult.failure(error: "Failed to get album info: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Input Parsing Helpers
    
    private func parseSearchAlbumInput(_ arguments: [String: Any]) throws -> SearchAlbumInput {
        guard let queryValue = arguments["query"] else {
            throw ToolError.missingParameter("query")
        }
        
        let query = "\(queryValue)"
        let limit = arguments.getInt(for: "limit") ?? 10
        
        // Validate limit bounds
        guard limit >= 1 && limit <= 50 else {
            throw ToolError.invalidParameterType("limit", expected: "integer between 1 and 50")
        }
        
        return SearchAlbumInput(
            query: query,
            limit: limit
        )
    }
    
    private func parseGetAlbumInfoInput(_ arguments: [String: Any]) throws -> GetAlbumInfoInput {
        guard let albumValue = arguments["album"] else {
            throw ToolError.missingParameter("album")
        }
        
        guard let artistValue = arguments["artist"] else {
            throw ToolError.missingParameter("artist")
        }
        
        let album = "\(albumValue)"
        let artist = "\(artistValue)"
        let autocorrect = arguments.getBool(for: "autocorrect") ?? true
        let username = arguments.getString(for: "username")
        let language = arguments.getString(for: "language") ?? "en"
        
        return GetAlbumInfoInput(
            album: album,
            artist: artist,
            autocorrect: autocorrect,
            username: username,
            language: language
        )
    }
}
