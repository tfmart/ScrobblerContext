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
    // Future tool categories will be added here:
    // private let userTools: UserTools
    // private let scrobbleTools: ScrobbleTools
    
    init(lastFMService: LastFMService) {
        self.authTools = AuthTools(lastFMService: lastFMService)
        self.artistTools = ArtistTools(lastFMService: lastFMService)
        self.albumTools = AlbumTools(lastFMService: lastFMService)
        self.trackTools = TrackTools(lastFMService: lastFMService)
        logger.info("Tool registry initialized with Auth, Artist, Album, and Track tools")
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
        
        // Future categories will be added here:
        // allTools.append(contentsOf: UserTools.createTools())
        // allTools.append(contentsOf: ScrobbleTools.createTools())
        
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
        // Future cases:
        // case .user:
        //     return UserTools.createTools()
        // case .scrobble:
        //     return ScrobbleTools.createTools()
        case .user, .scrobble, .unknown:
            logger.warning("Requested tools for unimplemented category: \(category.description)")
            return []
        }
    }
    
    /// Execute a tool by name
    func executeTool(name: String, arguments: [String: Any]) async throws -> ToolResult {
        logger.info("Executing tool: \(name)")
        
        // Determine which category the tool belongs to and execute
        let category = determineToolCategory(name)
        
        switch category {
        case .authentication:
            return try await authTools.execute(toolName: name, arguments: arguments)
        case .artist:
            return try await artistTools.execute(toolName: name, arguments: arguments)
        case .album:
            return try await albumTools.execute(toolName: name, arguments: arguments)
        case .track:
            return try await trackTools.execute(toolName: name, arguments: arguments)
        // Future cases:
        // case .user:
        //     return try await userTools.execute(toolName: name, arguments: arguments)
        // case .scrobble:
        //     return try await scrobbleTools.execute(toolName: name, arguments: arguments)
        case .user, .scrobble, .unknown:
            logger.error("Unknown or unimplemented tool requested: \(name)")
            throw ToolError.lastFMError("Unknown tool: \(name)")
        }
    }
    
    // MARK: - Private Helpers
    
    private func determineToolCategory(_ toolName: String) -> ToolCategory {
        // Authentication tools
        if toolName.hasPrefix("authenticate_") ||
           toolName.hasPrefix("set_session_") ||
           toolName.hasPrefix("check_auth_") {
            return .authentication
        }
        
        // Artist tools
        if toolName.hasPrefix("search_artist") ||
           toolName.hasPrefix("get_artist_") ||
           toolName.hasPrefix("get_similar_artists") {
            return .artist
        }
        
        // Album tools
        if toolName.hasPrefix("search_album") ||
           toolName.hasPrefix("get_album_") {
            return .album
        }
        
        // Track tools
        if toolName.hasPrefix("search_track") ||
           toolName.hasPrefix("get_track_") ||
           toolName.hasPrefix("get_similar_tracks") {
            return .track
        }
        
        // Future category detection:
        // if toolName.hasPrefix("search_album") ||
        //    toolName.hasPrefix("get_album_") {
        //     return .album
        // }
        
        // if toolName.hasPrefix("search_track") ||
        //    toolName.hasPrefix("get_track_") {
        //     return .track
        // }
        
        // if toolName.hasPrefix("get_user_") {
        //     return .user
        // }
        
        // if toolName.hasPrefix("scrobble_") ||
        //    toolName.hasPrefix("update_now_playing") {
        //     return .scrobble
        // }
        
        return .unknown
    }
}

// MARK: - Tool Categories

enum ToolCategory {
    case authentication
    case artist
    case album
    case track
    case user
    case scrobble
    case unknown
    
    var description: String {
        switch self {
        case .authentication:
            return "Authentication & Session Management"
        case .artist:
            return "Artist Information & Search"
        case .album:
            return "Album Information & Search"
        case .track:
            return "Track Information & Search"
        case .user:
            return "User Data & Statistics"
        case .scrobble:
            return "Scrobbling & Now Playing"
        case .unknown:
            return "Unknown Category"
        }
    }
}
