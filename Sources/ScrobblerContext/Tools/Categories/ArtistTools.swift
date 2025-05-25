//
//  ArtistTools.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 17/05/25.
//

import Foundation
import MCP
@preconcurrency import ScrobbleKit
import Logging

/// Artist-related tools for the Last.fm MCP Server
struct ArtistTools {
    private let lastFMService: LastFMService
    private let logger = Logger(label: "com.lastfm.mcp-server.artist")
    
    init(lastFMService: LastFMService) {
        self.lastFMService = lastFMService
    }
    
    // MARK: - Tool Definitions
    
    static func createTools() -> [Tool] {
        return [
            createSearchArtistTool(),
            createGetArtistInfoTool(),
            createGetSimilarArtistsTool()
        ]
    }
    
    private static func createSearchArtistTool() -> Tool {
        return Tool(
            name: "search_artist",
            description: "Search for artists on Last.fm by name",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "query": .object([
                        "type": .string("string"),
                        "description": .string("Artist name to search for")
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
    
    private static func createGetArtistInfoTool() -> Tool {
        return Tool(
            name: "get_artist_info",
            description: "Get detailed information about a specific artist including bio, stats, tags, and similar artists",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "name": .object([
                        "type": .string("string"),
                        "description": .string("Name of the artist to get information for")
                    ]),
                    "autocorrect": .object([
                        "type": .string("boolean"),
                        "description": .string("Automatically correct misspelled artist names"),
                        "default": .bool(true)
                    ]),
                    "username": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username for personalized data (optional)")
                    ]),
                    "language": .object([
                        "type": .string("string"),
                        "description": .string("Language for biography (ISO 639-1 code, e.g., 'en', 'es', 'fr')"),
                        "default": .string("en")
                    ])
                ]),
                "required": .array([.string("name")])
            ])
        )
    }
    
    private static func createGetSimilarArtistsTool() -> Tool {
        return Tool(
            name: "get_similar_artists",
            description: "Get artists similar to the specified artist, ranked by similarity",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "name": .object([
                        "type": .string("string"),
                        "description": .string("Name of the artist to find similar artists for")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Maximum number of similar artists to return (1-50)"),
                        "default": .int(10),
                        "minimum": .int(1),
                        "maximum": .int(50)
                    ]),
                    "autocorrect": .object([
                        "type": .string("boolean"),
                        "description": .string("Automatically correct misspelled artist names"),
                        "default": .bool(true)
                    ])
                ]),
                "required": .array([.string("name")])
            ])
        )
    }
    
    // MARK: - Tool Execution
    
    func execute(toolName: String, arguments: [String: (any Sendable)]) async throws -> ToolResult {
        logger.info("Executing artist tool: \(toolName)")
        
        switch toolName {
        case "search_artist":
            return try await executeSearchArtist(arguments: arguments)
        case "get_artist_info":
            return try await executeGetArtistInfo(arguments: arguments)
        case "get_similar_artists":
            return try await executeGetSimilarArtists(arguments: arguments)
        default:
            throw ToolError.lastFMError("Unknown artist tool: \(toolName)")
        }
    }
    
    // MARK: - Individual Tool Implementations
    
    private func executeSearchArtist(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseSearchArtistInput(arguments)
        
        do {
            let artists = try await lastFMService.searchArtist(
                query: input.query,
                limit: input.limit
            )
            
            logger.info("Found \(artists.count) artists for query: \(input.query)")
            
            let result = ResponseFormatters.format(artists)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Artist search failed for query '\(input.query)': \(error)")
            return ToolResult.failure(error: "Artist search failed: \(error.localizedDescription)")
        }
    }
    
    private func executeGetArtistInfo(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetArtistInfoInput(arguments)
        
        do {
            // For now, we'll use the basic getArtistInfo method
            // In the future, we can extend LastFMService to support additional parameters
            let artist = try await lastFMService.getArtistInfo(name: input.name)
            
            logger.info("Retrieved artist info for: \(input.name)")
            
            let result = ResponseFormatters.format(artist)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get artist info for '\(input.name)': \(error)")
            return ToolResult.failure(error: "Failed to get artist info: \(error.localizedDescription)")
        }
    }
    
    private func executeGetSimilarArtists(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetSimilarArtistsInput(arguments)
        
        do {
            let similarArtists = try await lastFMService.getSimilarArtists(
                name: input.name,
                limit: input.limit
            )
            
            logger.info("Found \(similarArtists.count) similar artists for: \(input.name)")
            
            let result = ResponseFormatters.format(similarArtists)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get similar artists for '\(input.name)': \(error)")
            return ToolResult.failure(error: "Failed to get similar artists: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Input Parsing Helpers
    
    private func parseSearchArtistInput(_ arguments: [String: (any Sendable)]) throws -> SearchArtistInput {
        guard let queryValue = arguments["query"] else {
            throw ToolError.missingParameter("query")
        }
        
        let query = "\(queryValue)"
        let limit = try arguments.getValidatedInt(for: "limit", min: 1, max: 50, default: 10) ?? 10
        
        return SearchArtistInput(
            query: query,
            limit: limit
        )
    }
    
    private func parseGetArtistInfoInput(_ arguments: [String: (any Sendable)]) throws -> GetArtistInfoInput {
        guard let nameValue = arguments["name"] else {
            throw ToolError.missingParameter("name")
        }
        
        let name = "\(nameValue)"
        let autocorrect = arguments.getBool(for: "autocorrect") ?? true
        let username = arguments.getString(for: "username")
        let language = arguments.getString(for: "language") ?? "en"
        
        return GetArtistInfoInput(
            name: name,
            autocorrect: autocorrect,
            username: username,
            language: language
        )
    }
    
    private func parseGetSimilarArtistsInput(_ arguments: [String: (any Sendable)]) throws -> GetSimilarArtistsInput {
        guard let nameValue = arguments["name"] else {
            throw ToolError.missingParameter("name")
        }
        
        let name = "\(nameValue)"
        let autocorrect = arguments.getBool(for: "autocorrect") ?? true
        let limit = try arguments.getValidatedInt(for: "limit", min: 1, max: 50, default: 10) ?? 10
        
        return GetSimilarArtistsInput(
            name: name,
            limit: limit,
            autocorrect: autocorrect
        )
    }
}
