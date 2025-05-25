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
            name: ToolName.searchArtist.rawValue,
            description: ToolName.searchArtist.description,
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
                    ]),
                    "page": .object([
                        "type": .string("integer"),
                        "description": .string("Page number for pagination (starts from 1)"),
                        "default": .int(1),
                        "minimum": .int(1)
                    ])
                ]),
                "required": .array([.string("query")])
            ])
        )
    }
    
    private static func createGetArtistInfoTool() -> Tool {
        return Tool(
            name: ToolName.getArtistInfo.rawValue,
            description: ToolName.getArtistInfo.description,
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
                    "user": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username for personalized data (optional)")
                    ]),
                    "language": .object([
                        "type": .string("string"),
                        "description": .string("Language for biography (ISO 639-1 code). Supported: en, fr, de, it, es, pt, nl, sv, no, da, fi, is, ru, pl, cs, hu, ro, tr, el, ar, he, hi, zh, ja, ko, vi, th, id"),
                        "default": .string("en"),
                        "enum": .array([
                            .string("en"), .string("fr"), .string("de"), .string("it"), .string("es"), .string("pt"),
                            .string("nl"), .string("sv"), .string("no"), .string("da"), .string("fi"), .string("is"),
                            .string("ru"), .string("pl"), .string("cs"), .string("hu"), .string("ro"), .string("tr"),
                            .string("el"), .string("ar"), .string("he"), .string("hi"), .string("zh"), .string("ja"),
                            .string("ko"), .string("vi"), .string("th"), .string("id")
                        ])
                    ])
                ]),
                "required": .array([.string("name")])
            ])
        )
    }
    
    private static func createGetSimilarArtistsTool() -> Tool {
        return Tool(
            name: ToolName.getSimilarArtists.rawValue,
            description: ToolName.getSimilarArtists.description,
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
    
    func execute(toolName: ToolName, arguments: [String: (any Sendable)]) async throws -> ToolResult {
        logger.info("Executing artist tool: \(toolName.rawValue)")
        
        switch toolName {
        case .searchArtist:
            return try await executeSearchArtist(arguments: arguments)
        case .getArtistInfo:
            return try await executeGetArtistInfo(arguments: arguments)
        case .getSimilarArtists:
            return try await executeGetSimilarArtists(arguments: arguments)
        default:
            throw ToolError.lastFMError("Invalid artist tool: \(toolName.rawValue)")
        }
    }
    
    // MARK: - Individual Tool Implementations
    
    private func executeSearchArtist(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseSearchArtistInput(arguments)
        
        do {
            let artists = try await lastFMService.searchArtist(
                query: input.query,
                limit: input.limit,
                page: input.page
            )
            
            logger.info("Found \(artists.count) artists for query: \(input.query) (page: \(input.page))")
            
            let result = ResponseFormatters.format(artists)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Artist search failed for query '\(input.query)' (page: \(input.page)): \(error)")
            return ToolResult.failure(error: "Artist search failed: \(error.localizedDescription)")
        }
    }
    
    private func executeGetArtistInfo(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetArtistInfoInput(arguments)
        
        do {
            let artist = try await lastFMService.getArtistInfo(
                name: input.name,
                autocorrect: input.autocorrect,
                username: input.username,
                language: input.language
            )
            
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
                limit: input.limit,
                autocorrect: input.autocorrect
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
    
    private func validateLanguageCode(_ language: String) throws -> String {
        let supportedLanguages = [
            "en", "fr", "de", "it", "es", "pt", "nl", "sv", "no", "da",
            "fi", "is", "ru", "pl", "cs", "hu", "ro", "tr", "el", "ar",
            "he", "hi", "zh", "ja", "ko", "vi", "th", "id"
        ]
        
        guard supportedLanguages.contains(language) else {
            throw ToolError.invalidParameterType("language", expected: "supported ISO 639-1 code: \(supportedLanguages.joined(separator: ", "))")
        }
        
        return language
    }
    
    private func parseSearchArtistInput(_ arguments: [String: (any Sendable)]) throws -> SearchArtistInput {
        guard let queryValue = arguments["query"] else {
            throw ToolError.missingParameter("query")
        }
        
        let query = "\(queryValue)"
        let limit = try arguments.getValidatedInt(for: "limit", min: 1, max: 50, default: 10) ?? 10
        let page = try arguments.getValidatedInt(for: "page", min: 1, max: Int.max, default: 1) ?? 1
        
        return SearchArtistInput(
            query: query,
            limit: limit,
            page: page
        )
    }
    
    private func parseGetArtistInfoInput(_ arguments: [String: (any Sendable)]) throws -> GetArtistInfoInput {
        guard let nameValue = arguments["name"] else {
            throw ToolError.missingParameter("name")
        }
        
        let name = "\(nameValue)"
        let autocorrect = arguments.getBool(for: "autocorrect") ?? true
        let username = arguments.getString(for: "user")
        let languageInput = arguments.getString(for: "language") ?? "en"
        let language = try validateLanguageCode(languageInput)
        
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
