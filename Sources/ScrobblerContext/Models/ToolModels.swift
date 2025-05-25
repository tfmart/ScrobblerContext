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
