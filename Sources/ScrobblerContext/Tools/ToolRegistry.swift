//
//  ToolRegistry.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 17/05/25.
//

import Foundation
import MCP
import Logging

/// Registry for managing all available MCP tools
struct ToolRegistry {
    private let logger = Logger(label: "com.lastfm.mcp-server.registry")
    
    // MARK: - Tool Categories
    
    private let authTools: AuthTools
    private let artistTools: ArtistTools
    private let albumTools: AlbumTools
    private let trackTools: TrackTools
    private let userTools: UserTools
    private let scrobbleTools: ScrobbleTools
    
    init(lastFMService: LastFMService) {
        self.authTools = AuthTools(lastFMService: lastFMService)
        self.artistTools = ArtistTools(lastFMService: lastFMService)
        self.albumTools = AlbumTools(lastFMService: lastFMService)
        self.trackTools = TrackTools(lastFMService: lastFMService)
        self.userTools = UserTools(lastFMService: lastFMService)
        self.scrobbleTools = ScrobbleTools(lastFMService: lastFMService)
        logger.info("Tool registry initialized with ALL service categories: Auth, Artist, Album, Track, User, and Scrobble tools")
    }
    
    // MARK: - Public Interface
    
    /// Returns all available tools across all categories
    func getAllTools() -> [Tool] {
        logger.info("Generating complete tool list")
        
        var allTools: [Tool] = []
        
        // Add authentication tools
        allTools.append(contentsOf: AuthTools.createTools())
        
        // Add artist tools
        allTools.append(contentsOf: ArtistTools.createTools())
        
        // Add album tools
        allTools.append(contentsOf: AlbumTools.createTools())
        
        // Add track tools
        allTools.append(contentsOf: TrackTools.createTools())
        
        // Add user tools
        allTools.append(contentsOf: UserTools.createTools())
        
        // Add scrobble tools
        allTools.append(contentsOf: ScrobbleTools.createTools())
        
        logger.info("Registered \(allTools.count) tools total")
        return allTools
    }
    
    /// Returns tools for a specific category
    func getToolsForCategory(_ category: ToolCategory) -> [Tool] {
        switch category {
        case .authentication:
            return AuthTools.createTools()
        case .artist:
            return ArtistTools.createTools()
        case .album:
            return AlbumTools.createTools()
        case .track:
            return TrackTools.createTools()
        case .user:
            return UserTools.createTools()
        case .scrobble:
            return ScrobbleTools.createTools()
        case .unknown:
            logger.warning("Requested tools for unknown category: \(category.description)")
            return []
        }
    }
    
    /// Execute a tool by name
    func executeTool(name: String, arguments: [String: (any Sendable)]) async throws -> ToolResult {
        logger.info("Executing tool: \(name)")
        
        // Convert string to ToolName enum
        guard let toolName = ToolName(rawValue: name) else {
            logger.error("Unknown tool requested: \(name)")
            throw ToolError.lastFMError("Unknown tool: \(name)")
        }
        
        // Execute based on tool category
        switch toolName.category {
        case .authentication:
            return try await authTools.execute(toolName: toolName, arguments: arguments)
        case .artist:
            return try await artistTools.execute(toolName: toolName, arguments: arguments)
        case .album:
            return try await albumTools.execute(toolName: toolName, arguments: arguments)
        case .track:
            return try await trackTools.execute(toolName: toolName, arguments: arguments)
        case .user:
            return try await userTools.execute(toolName: toolName, arguments: arguments)
        case .scrobble:
            return try await scrobbleTools.execute(toolName: toolName, arguments: arguments)
        case .unknown:
            logger.error("Unknown tool category for: \(name)")
            throw ToolError.lastFMError("Unknown tool category: \(name)")
        }
    }
}
