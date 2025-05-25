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
            createGetAlbumInfoTool(),
            createAddAlbumTagsTool(),
            createGetAlbumTagsTool(),
            createGetAlbumTopTagsTool(),
            createRemoveAlbumTagTool()
        ]
    }
    
    private static func createSearchAlbumTool() -> Tool {
        return Tool(
            name: ToolName.searchAlbum.rawValue,
            description: ToolName.searchAlbum.description,
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
    
    private static func createGetAlbumInfoTool() -> Tool {
        return Tool(
            name: ToolName.getAlbumInfo.rawValue,
            description: ToolName.getAlbumInfo.description,
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
                        "description": .string("Language for album information (ISO 639-1 code). Supported: en, fr, de, it, es, pt, nl, sv, no, da, fi, is, ru, pl, cs, hu, ro, tr, el, ar, he, hi, zh, ja, ko, vi, th, id"),
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
                "required": .array([.string("album"), .string("artist")])
            ])
        )
    }
    
    private static func createAddAlbumTagsTool() -> Tool {
        return Tool(
            name: ToolName.addAlbumTags.rawValue,
            description: ToolName.addAlbumTags.description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "album": .object([
                        "type": .string("string"),
                        "description": .string("Name of the album to add tags to")
                    ]),
                    "artist": .object([
                        "type": .string("string"),
                        "description": .string("Name of the artist who created the album")
                    ]),
                    "tags": .object([
                        "type": .string("array"),
                        "items": .object([
                            "type": .string("string")
                        ]),
                        "description": .string("Array of tags to add to the album (maximum 10 tags)"),
                        "maxItems": .int(10)
                    ])
                ]),
                "required": .array([.string("album"), .string("artist"), .string("tags")])
            ])
        )
    }
    
    private static func createGetAlbumTagsTool() -> Tool {
        return Tool(
            name: ToolName.getAlbumTags.rawValue,
            description: ToolName.getAlbumTags.description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "album": .object([
                        "type": .string("string"),
                        "description": .string("Name of the album to get tags for")
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
                        "description": .string("Username to get tags from (optional, if not provided returns all user tags)")
                    ])
                ]),
                "required": .array([.string("album"), .string("artist")])
            ])
        )
    }
    
    private static func createGetAlbumTopTagsTool() -> Tool {
        return Tool(
            name: ToolName.getAlbumTopTags.rawValue,
            description: ToolName.getAlbumTopTags.description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "album": .object([
                        "type": .string("string"),
                        "description": .string("Name of the album to get top tags for")
                    ]),
                    "artist": .object([
                        "type": .string("string"),
                        "description": .string("Name of the artist who created the album")
                    ]),
                    "autocorrect": .object([
                        "type": .string("boolean"),
                        "description": .string("Automatically correct misspelled album/artist names"),
                        "default": .bool(true)
                    ])
                ]),
                "required": .array([.string("album"), .string("artist")])
            ])
        )
    }
    
    private static func createRemoveAlbumTagTool() -> Tool {
        return Tool(
            name: ToolName.removeAlbumTag.rawValue,
            description: ToolName.removeAlbumTag.description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "album": .object([
                        "type": .string("string"),
                        "description": .string("Name of the album to remove the tag from")
                    ]),
                    "artist": .object([
                        "type": .string("string"),
                        "description": .string("Name of the artist who created the album")
                    ]),
                    "tag": .object([
                        "type": .string("string"),
                        "description": .string("Tag to remove from the album")
                    ])
                ]),
                "required": .array([.string("album"), .string("artist"), .string("tag")])
            ])
        )
    }
    
    // MARK: - Tool Execution
    
    func execute(toolName: ToolName, arguments: [String: (any Sendable)]) async throws -> ToolResult {
        logger.info("Executing album tool: \(toolName.rawValue)")
        
        switch toolName {
        case .searchAlbum:
            return try await executeSearchAlbum(arguments: arguments)
        case .getAlbumInfo:
            return try await executeGetAlbumInfo(arguments: arguments)
        case .addAlbumTags:
            return try await executeAddAlbumTags(arguments: arguments)
        case .getAlbumTags:
            return try await executeGetAlbumTags(arguments: arguments)
        case .getAlbumTopTags:
            return try await executeGetAlbumTopTags(arguments: arguments)
        case .removeAlbumTag:
            return try await executeRemoveAlbumTag(arguments: arguments)
        default:
            throw ToolError.lastFMError("Invalid album tool: \(toolName.rawValue)")
        }
    }
    
    // MARK: - Individual Tool Implementations
    
    private func executeSearchAlbum(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseSearchAlbumInput(arguments)
        
        do {
            let albums = try await lastFMService.searchAlbum(
                query: input.query,
                limit: input.limit,
                page: input.page
            )
            
            logger.info("Found \(albums.count) albums for query: \(input.query) (page: \(input.page))")
            
            let result = ResponseFormatters.format(albums)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Album search failed for query '\(input.query)' (page: \(input.page)): \(error)")
            return ToolResult.failure(error: "Album search failed: \(error.localizedDescription)")
        }
    }
    
    private func executeGetAlbumInfo(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetAlbumInfoInput(arguments)
        
        do {
            let album = try await lastFMService.getAlbumInfo(
                album: input.album,
                artist: input.artist,
                autocorrect: input.autocorrect,
                username: input.username,
                language: input.language
            )
            
            logger.info("Retrieved album info for: '\(input.album)' by \(input.artist)")
            
            let result = ResponseFormatters.format(album)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get album info for '\(input.album)' by '\(input.artist)': \(error)")
            return ToolResult.failure(error: "Failed to get album info: \(error.localizedDescription)")
        }
    }
    
    private func executeAddAlbumTags(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseAddAlbumTagsInput(arguments)
        
        do {
            let success = try await lastFMService.addTagsToAlbum(
                album: input.album,
                artist: input.artist,
                tags: input.tags
            )
            
            logger.info("Add tags operation for album '\(input.album)' by '\(input.artist)': \(success ? "success" : "failed")")
            
            let result = ResponseFormatters.formatTagOperationResult(
                success: success,
                operation: "add_tags",
                artist: input.artist,
                tags: input.tags
            )
            var resultWithAlbum = result
            resultWithAlbum["album"] = input.album
            
            return ToolResult.success(data: resultWithAlbum)
            
        } catch {
            logger.error("Failed to add tags to album '\(input.album)' by '\(input.artist)': \(error)")
            return ToolResult.failure(error: "Failed to add tags: \(error.localizedDescription)")
        }
    }
    
    private func executeGetAlbumTags(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetAlbumTagsInput(arguments)
        
        do {
            let tags = try await lastFMService.getAlbumTags(
                album: input.album,
                artist: input.artist,
                autocorrect: input.autocorrect,
                username: input.username
            )
            
            logger.info("Retrieved \(tags.count) tags for album: '\(input.album)' by '\(input.artist)'")
            
            let result = ResponseFormatters.format(tags)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get tags for album '\(input.album)' by '\(input.artist)': \(error)")
            return ToolResult.failure(error: "Failed to get album tags: \(error.localizedDescription)")
        }
    }
    
    private func executeGetAlbumTopTags(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseGetAlbumTopTagsInput(arguments)
        
        do {
            let tags = try await lastFMService.getAlbumTopTags(
                album: input.album,
                artist: input.artist,
                autocorrect: input.autocorrect
            )
            
            logger.info("Retrieved \(tags.count) top tags for album: '\(input.album)' by '\(input.artist)'")
            
            let result = ResponseFormatters.format(tags)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to get top tags for album '\(input.album)' by '\(input.artist)': \(error)")
            return ToolResult.failure(error: "Failed to get album top tags: \(error.localizedDescription)")
        }
    }
    
    private func executeRemoveAlbumTag(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseRemoveAlbumTagInput(arguments)
        
        do {
            let success = try await lastFMService.removeTagFromAlbum(
                album: input.album,
                artist: input.artist,
                tag: input.tag
            )
            
            logger.info("Remove tag operation for album '\(input.album)' by '\(input.artist)': \(success ? "success" : "failed")")
            
            let result = ResponseFormatters.formatTagOperationResult(
                success: success,
                operation: "remove_tag",
                artist: input.artist,
                tag: input.tag
            )
            var resultWithAlbum = result
            resultWithAlbum["album"] = input.album
            
            return ToolResult.success(data: resultWithAlbum)
            
        } catch {
            logger.error("Failed to remove tag from album '\(input.album)' by '\(input.artist)': \(error)")
            return ToolResult.failure(error: "Failed to remove tag: \(error.localizedDescription)")
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
    
    private func parseSearchAlbumInput(_ arguments: [String: (any Sendable)]) throws -> SearchAlbumInput {
        guard let queryValue = arguments["query"] else {
            throw ToolError.missingParameter("query")
        }
        
        let query = "\(queryValue)"
        let limit = try arguments.getValidatedInt(for: "limit", min: 1, max: 50, default: 10) ?? 10
        let page = try arguments.getValidatedInt(for: "page", min: 1, max: Int.max, default: 1) ?? 1
        
        return SearchAlbumInput(
            query: query,
            limit: limit,
            page: page
        )
    }
    
    private func parseGetAlbumInfoInput(_ arguments: [String: (any Sendable)]) throws -> GetAlbumInfoInput {
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
        let languageInput = arguments.getString(for: "language") ?? "en"
        let language = try validateLanguageCode(languageInput)
        
        return GetAlbumInfoInput(
            album: album,
            artist: artist,
            autocorrect: autocorrect,
            username: username,
            language: language
        )
    }
    
    private func parseAddAlbumTagsInput(_ arguments: [String: (any Sendable)]) throws -> AddAlbumTagsInput {
        guard let albumValue = arguments["album"] else {
            throw ToolError.missingParameter("album")
        }
        
        guard let artistValue = arguments["artist"] else {
            throw ToolError.missingParameter("artist")
        }
        
        guard let tagsValue = arguments["tags"] else {
            throw ToolError.missingParameter("tags")
        }
        
        let album = "\(albumValue)"
        let artist = "\(artistValue)"
        
        // Parse tags array
        var tags: [String] = []
        if let tagsArray = tagsValue as? [Any] {
            tags = tagsArray.compactMap { "\($0)" }
        } else {
            throw ToolError.invalidParameterType("tags", expected: "array of strings")
        }
        
        guard !tags.isEmpty else {
            throw ToolError.invalidParameterType("tags", expected: "non-empty array of strings")
        }
        
        guard tags.count <= 10 else {
            throw ToolError.invalidParameterType("tags", expected: "maximum 10 tags")
        }
        
        return AddAlbumTagsInput(album: album, artist: artist, tags: tags)
    }
    
    private func parseGetAlbumTagsInput(_ arguments: [String: (any Sendable)]) throws -> GetAlbumTagsInput {
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
        
        return GetAlbumTagsInput(
            album: album,
            artist: artist,
            autocorrect: autocorrect,
            username: username
        )
    }
    
    private func parseGetAlbumTopTagsInput(_ arguments: [String: (any Sendable)]) throws -> GetAlbumTopTagsInput {
        guard let albumValue = arguments["album"] else {
            throw ToolError.missingParameter("album")
        }
        
        guard let artistValue = arguments["artist"] else {
            throw ToolError.missingParameter("artist")
        }
        
        let album = "\(albumValue)"
        let artist = "\(artistValue)"
        let autocorrect = arguments.getBool(for: "autocorrect") ?? true
        
        return GetAlbumTopTagsInput(
            album: album,
            artist: artist,
            autocorrect: autocorrect
        )
    }
    
    private func parseRemoveAlbumTagInput(_ arguments: [String: (any Sendable)]) throws -> RemoveAlbumTagInput {
        guard let albumValue = arguments["album"] else {
            throw ToolError.missingParameter("album")
        }
        
        guard let artistValue = arguments["artist"] else {
            throw ToolError.missingParameter("artist")
        }
        
        guard let tagValue = arguments["tag"] else {
            throw ToolError.missingParameter("tag")
        }
        
        let album = "\(albumValue)"
        let artist = "\(artistValue)"
        let tag = "\(tagValue)"
        
        return RemoveAlbumTagInput(album: album, artist: artist, tag: tag)
    }
}
