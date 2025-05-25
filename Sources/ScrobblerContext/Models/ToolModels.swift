//
//  ToolModels.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 17/05/25.
//

import Foundation

// MARK: - Tool Input Models

/// Base protocol for all tool inputs
protocol ToolInput {
    static var requiredParameters: [String] { get }
    static var optionalParameters: [String: (any Sendable)?] { get }
}

// MARK: - Authentication
struct AuthenticateInput: ToolInput {
    let username: String
    let password: String
    
    static let requiredParameters = ["username", "password"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}

// MARK: - Artist Tools
struct SearchArtistInput: ToolInput {
    let query: String
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["query"]
    static let optionalParameters: [String: (any Sendable)?] = ["limit": 10, "page": 1]
}

struct GetArtistInfoInput: ToolInput {
    let name: String
    let autocorrect: Bool
    let username: String?
    let language: String
    
    static let requiredParameters = ["name"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "autocorrect": true,
        "username": "",
        "language": "en"
    ]
}

struct GetSimilarArtistsInput: ToolInput {
    let name: String
    let limit: Int
    let autocorrect: Bool
    
    static let requiredParameters = ["name"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "limit": 10,
        "autocorrect": true
    ]
}

struct AddArtistTagsInput: ToolInput {
    let artist: String
    let tags: [String]
    
    static let requiredParameters = ["artist", "tags"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}

struct GetArtistCorrectionInput: ToolInput {
    let artist: String
    
    static let requiredParameters = ["artist"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}

struct GetArtistTagsInput: ToolInput {
    let name: String
    let user: String?
    let autocorrect: Bool
    
    static let requiredParameters = ["name"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "user": "",
        "autocorrect": true
    ]
}

struct GetArtistTopAlbumsInput: ToolInput {
    let name: String
    let limit: Int
    let page: Int
    let autocorrect: Bool
    
    static let requiredParameters = ["name"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "limit": 50,
        "page": 1,
        "autocorrect": true
    ]
}

struct GetArtistTopTracksInput: ToolInput {
    let name: String
    let limit: Int
    let page: Int
    let autocorrect: Bool
    
    static let requiredParameters = ["name"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "limit": 50,
        "page": 1,
        "autocorrect": true
    ]
}

struct RemoveArtistTagInput: ToolInput {
    let artist: String
    let tag: String
    
    static let requiredParameters = ["artist", "tag"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}

// MARK: - Album Tools
struct SearchAlbumInput: ToolInput {
    let query: String
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["query"]
    static let optionalParameters: [String: (any Sendable)?] = ["limit": 10, "page": 1]
}

struct GetAlbumInfoInput: ToolInput {
    let album: String
    let artist: String
    let autocorrect: Bool
    let username: String?
    let language: String
    
    static let requiredParameters = ["album", "artist"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "autocorrect": true,
        "username": "",
        "language": "en"
    ]
}

struct AddAlbumTagsInput: ToolInput {
    let album: String
    let artist: String
    let tags: [String]
    
    static let requiredParameters = ["album", "artist", "tags"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}

struct GetAlbumTagsInput: ToolInput {
    let album: String
    let artist: String
    let autocorrect: Bool
    let username: String?
    
    static let requiredParameters = ["album", "artist"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "autocorrect": true,
        "username": ""
    ]
}

struct GetAlbumTopTagsInput: ToolInput {
    let album: String
    let artist: String
    let autocorrect: Bool
    
    static let requiredParameters = ["album", "artist"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "autocorrect": true
    ]
}

struct RemoveAlbumTagInput: ToolInput {
    let album: String
    let artist: String
    let tag: String
    
    static let requiredParameters = ["album", "artist", "tag"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}

// MARK: - Track Tools
struct SearchTrackInput: ToolInput {
    let query: String
    let artist: String?
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["query"]
    static let optionalParameters: [String: (any Sendable)?] = ["artist": "", "limit": 10, "page": 1]
}

struct GetTrackInfoInput: ToolInput {
    let track: String
    let artist: String
    let username: String?
    let autocorrect: Bool
    let language: String
    
    static let requiredParameters = ["track", "artist"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "username": "",
        "autocorrect": false,
        "language": "en"
    ]
}

struct GetSimilarTracksInput: ToolInput {
    let track: String
    let artist: String
    let autocorrect: Bool
    let limit: Int?
    
    static let requiredParameters = ["track", "artist"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "autocorrect": true,
        "limit": nil
    ]
}

struct GetTrackCorrectionInput: ToolInput {
    let track: String
    let artist: String
    
    static let requiredParameters = ["track", "artist"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}

struct GetTrackTagsInput: ToolInput {
    let track: String
    let artist: String
    let autocorrect: Bool
    let username: String?
    
    static let requiredParameters = ["track", "artist"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "autocorrect": true,
        "username": ""
    ]
}

struct GetTrackTopTagsInput: ToolInput {
    let track: String
    let artist: String
    let autocorrect: Bool
    
    static let requiredParameters = ["track", "artist"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "autocorrect": true
    ]
}

struct AddTrackTagsInput: ToolInput {
    let track: String
    let artist: String
    let tags: [String]
    
    static let requiredParameters = ["track", "artist", "tags"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}

struct RemoveTrackTagInput: ToolInput {
    let track: String
    let artist: String
    let tag: String
    
    static let requiredParameters = ["track", "artist", "tag"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}

// MARK: - User Tools
struct GetUserRecentTracksInput: ToolInput {
    let username: String
    let limit: Int
    let page: Int
    let startDate: Date?
    let extended: Bool
    let endDate: Date?
    
    static let requiredParameters = ["username"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "limit": 50,
        "page": 1,
        "start_date": 0,
        "extended": false,
        "end_date": 0
    ]
}

struct GetUserTopArtistsInput: ToolInput {
    let username: String
    let period: String
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["username"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "period": "overall",
        "limit": 10,
        "page": 1
    ]
}

struct GetUserTopTracksInput: ToolInput {
    let username: String
    let period: String
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["username"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "period": "overall",
        "limit": 10,
        "page": 1
    ]
}

struct GetUserInfoInput: ToolInput {
    let username: String
    
    static let requiredParameters = ["username"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}

struct GetUserFriendsInput: ToolInput {
    let username: String
    let recentTracks: Bool
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["username"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "recent_tracks": false,
        "limit": 50,
        "page": 1
    ]
}

struct GetUserLovedTracksInput: ToolInput {
    let username: String
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["username"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "limit": 50,
        "page": 1
    ]
}

struct GetUserPersonalTagsForArtistsInput: ToolInput {
    let username: String
    let tag: String
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["username", "tag"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "limit": 50,
        "page": 1
    ]
}

struct GetUserTopAlbumsInput: ToolInput {
    let username: String
    let period: String
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["username"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "period": "overall",
        "limit": 50,
        "page": 1
    ]
}

struct GetUserTopTagsInput: ToolInput {
    let username: String
    let limit: Int?
    
    static let requiredParameters = ["username"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "limit": nil
    ]
}

// MARK: - Scrobble Tools
struct ScrobbleTrackInput: ToolInput {
    let artist: String
    let track: String
    let timestamp: Date?
    let album: String?
    let albumArtist: String?
    let trackNumber: Int?
    let duration: Int?
    let chosenByUser: Bool?
    let mbid: String?
    
    static let requiredParameters = ["artist", "track"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "timestamp": 0,
        "album": "",
        "album_artist": "",
        "track_number": 0,
        "duration": 0,
        "chosen_by_user": false,
        "mbid": ""
    ]
}

struct ScrobbleMultipleTracksInput: ToolInput {
    let tracks: [[String: Any]]
    
    static let requiredParameters = ["tracks"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}

struct UpdateNowPlayingInput: ToolInput {
    let artist: String
    let track: String
    let album: String?
    let trackNumber: Int?
    let context: String?
    let mbid: String?
    let duration: Int?
    let albumArtist: String?
    
    static let requiredParameters = ["artist", "track"]
    static let optionalParameters: [String: (any Sendable)?] = [
        "album": "",
        "track_number": 0,
        "context": "",
        "mbid": "",
        "duration": 0,
        "album_artist": ""
    ]
}

struct LoveTrackInput: ToolInput {
    let artist: String
    let track: String
    
    static let requiredParameters = ["artist", "track"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}

struct UnloveTrackInput: ToolInput {
    let artist: String
    let track: String
    
    static let requiredParameters = ["artist", "track"]
    static let optionalParameters: [String: (any Sendable)?] = [:]
}

// MARK: - Tool Output Models

struct ToolResult {
    let success: Bool
    let data: [String: Any]?
    let error: String?
    
    static func success(data: [String: Any]) -> ToolResult {
        return ToolResult(success: true, data: data, error: nil)
    }
    
    static func failure(error: String) -> ToolResult {
        return ToolResult(success: false, data: nil, error: error)
    }
    
    func toJSON() throws -> String {
        var result: [String: Any] = ["success": success]
        
        if let data = data {
            result.merge(data) { _, new in new }
        }
        
        if let error = error {
            result["error"] = error
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted])
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ToolError.jsonSerializationFailed
        }
        return jsonString
    }
}
