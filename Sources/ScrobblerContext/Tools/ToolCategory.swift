//
//  ToolCategory.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 24/05/25.
//


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
