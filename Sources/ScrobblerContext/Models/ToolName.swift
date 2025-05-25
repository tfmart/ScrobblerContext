//
//  ToolName.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 24/05/25.
//

import Foundation

/// Enum representing all available tool names in the Last.fm MCP Server
enum ToolName: String, CaseIterable {
    // MARK: - Authentication Tools
    case authenticateUser = "authenticate_user"
    case setSessionKey = "set_session_key"
    case checkAuthStatus = "check_auth_status"
    
    // MARK: - Artist Tools
    case searchArtist = "search_artist"
    case getArtistInfo = "get_artist_info"
    case getSimilarArtists = "get_similar_artists"
    case addArtistTags = "add_artist_tags"
    case getArtistCorrection = "get_artist_correction"
    case getArtistTags = "get_artist_tags"
    case getArtistTopAlbums = "get_artist_top_albums"
    case getArtistTopTracks = "get_artist_top_tracks"
    case removeArtistTag = "remove_artist_tag"
    
    // MARK: - Album Tools
    case searchAlbum = "search_album"
    case getAlbumInfo = "get_album_info"
    case addAlbumTags = "add_album_tags"
    case getAlbumTags = "get_album_tags"
    case getAlbumTopTags = "get_album_top_tags"
    case removeAlbumTag = "remove_album_tag"
    
    // MARK: - Track Tools
    case searchTrack = "search_track"
    case getTrackInfo = "get_track_info"
    case getSimilarTracks = "get_similar_tracks"
    case getTrackCorrection = "get_track_correction"
    case getTrackTags = "get_track_tags"
    case getTrackTopTags = "get_track_top_tags"
    case addTrackTags = "add_track_tags"
    case removeTrackTag = "remove_track_tag"
    
    // MARK: - User Tools
    case getUserRecentTracks = "get_user_recent_tracks"
    case getUserTopArtists = "get_user_top_artists"
    case getUserTopTracks = "get_user_top_tracks"
    case getUserInfo = "get_user_info"
    case getUserFriends = "get_user_friends"
    case getUserLovedTracks = "get_user_loved_tracks"
    case getUserPersonalTagsForArtists = "get_user_personal_tags_for_artists"
    case getUserTopAlbums = "get_user_top_albums"
    case getUserTopTags = "get_user_top_tags"
    
    // MARK: - Scrobble Tools
    case scrobbleTrack = "scrobble_track"
    case scrobbleMultipleTracks = "scrobble_multiple_tracks"
    case updateNowPlaying = "update_now_playing"
    case loveTrack = "love_track"
    case unloveTrack = "unlove_track"
    
    // MARK: - Computed Properties
    
    /// The category this tool belongs to
    var category: ToolCategory {
        switch self {
        case .authenticateUser, .setSessionKey, .checkAuthStatus:
            return .authentication
        case .searchArtist, .getArtistInfo, .getSimilarArtists, .addArtistTags, .getArtistCorrection, .getArtistTags, .getArtistTopAlbums, .getArtistTopTracks, .removeArtistTag:
            return .artist
        case .searchAlbum, .getAlbumInfo, .addAlbumTags, .getAlbumTags, .getAlbumTopTags, .removeAlbumTag:
            return .album
        case .searchTrack, .getTrackInfo, .getSimilarTracks, .getTrackCorrection, .getTrackTags, .getTrackTopTags, .addTrackTags, .removeTrackTag:
            return .track
        case .getUserRecentTracks, .getUserTopArtists, .getUserTopTracks, .getUserInfo, .getUserFriends, .getUserLovedTracks, .getUserPersonalTagsForArtists, .getUserTopAlbums, .getUserTopTags:
            return .user
        case .scrobbleTrack, .scrobbleMultipleTracks, .updateNowPlaying, .loveTrack, .unloveTrack:
            return .scrobble
        }
    }
    
    /// Whether this tool requires authentication
    var requiresAuthentication: Bool {
        switch self {
        case .scrobbleTrack, .scrobbleMultipleTracks, .updateNowPlaying, .loveTrack, .unloveTrack, .addArtistTags, .removeArtistTag, .addAlbumTags, .removeAlbumTag, .addTrackTags, .removeTrackTag:
            return true
        case .setSessionKey, .authenticateUser:
            return false // These tools establish authentication
        default:
            return false // Most read-only tools don't require auth
        }
    }
    
    /// Human-readable description of the tool
    var description: String {
        switch self {
        case .authenticateUser:
            return "Authenticate with Last.fm using username and password"
        case .setSessionKey:
            return "Set an existing Last.fm session key for authentication"
        case .checkAuthStatus:
            return "Check if the user is currently authenticated with Last.fm"
        case .searchArtist:
            return "Search for artists on Last.fm by name"
        case .getArtistInfo:
            return "Get detailed information about a specific artist"
        case .getSimilarArtists:
            return "Get artists similar to the specified artist"
        case .addArtistTags:
            return "Add tags to an artist (requires authentication)"
        case .getArtistCorrection:
            return "Get corrected artist name if available"
        case .getArtistTags:
            return "Get tags applied to an artist by a user or all users"
        case .getArtistTopAlbums:
            return "Get top albums for an artist"
        case .getArtistTopTracks:
            return "Get top tracks for an artist"
        case .removeArtistTag:
            return "Remove a tag from an artist (requires authentication)"
        case .searchAlbum:
            return "Search for albums on Last.fm by name"
        case .getAlbumInfo:
            return "Get detailed information about a specific album"
        case .addAlbumTags:
            return "Add tags to an album (requires authentication)"
        case .getAlbumTags:
            return "Get tags applied to an album by a user or all users"
        case .getAlbumTopTags:
            return "Get top tags for an album ordered by popularity"
        case .removeAlbumTag:
            return "Remove a tag from an album (requires authentication)"
        case .searchTrack:
            return "Search for tracks on Last.fm by name"
        case .getTrackInfo:
            return "Get detailed information about a specific track"
        case .getSimilarTracks:
            return "Get tracks similar to the specified track"
        case .getTrackCorrection:
            return "Get corrected track and artist names if available"
        case .getTrackTags:
            return "Get tags applied to a track by a user or all users"
        case .getTrackTopTags:
            return "Get top tags for a track ordered by popularity"
        case .addTrackTags:
            return "Add tags to a track (requires authentication)"
        case .removeTrackTag:
            return "Remove a tag from a track (requires authentication)"
        case .getUserRecentTracks:
            return "Get a user's recently played tracks from Last.fm"
        case .getUserTopArtists:
            return "Get a user's top artists based on their listening history"
        case .getUserTopTracks:
            return "Get a user's top tracks based on their listening history"
        case .getUserInfo:
            return "Get detailed information about a Last.fm user's profile"
        case .getUserFriends:
            return "Get a user's friends list from Last.fm"
        case .getUserLovedTracks:
            return "Get a user's loved tracks from Last.fm"
        case .getUserPersonalTagsForArtists:
            return "Get artists tagged with a specific personal tag by a user"
        case .getUserTopAlbums:
            return "Get a user's top albums based on their listening history"
        case .getUserTopTags:
            return "Get a user's top tags ordered by usage"
        case .scrobbleTrack:
            return "Scrobble a track to the authenticated user's Last.fm profile"
        case .scrobbleMultipleTracks:
            return "Scrobble multiple tracks at once to the authenticated user's Last.fm profile"
        case .updateNowPlaying:
            return "Update the currently playing track for the authenticated user"
        case .loveTrack:
            return "Mark a track as loved for the authenticated user"
        case .unloveTrack:
            return "Remove a track from the authenticated user's loved tracks"
        }
    }
    
    // MARK: - Static Methods
    
    /// Get all tools for a specific category
    static func toolsForCategory(_ category: ToolCategory) -> [ToolName] {
        return allCases.filter { $0.category == category }
    }
    
    /// Get all tools that require authentication
    static var authenticationRequiredTools: [ToolName] {
        return allCases.filter { $0.requiresAuthentication }
    }
    
    /// Get all tools that don't require authentication
    static var publicTools: [ToolName] {
        return allCases.filter { !$0.requiresAuthentication }
    }
}
