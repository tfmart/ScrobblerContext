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
    static var optionalParameters: [String: (any Sendable)] { get }
}

// MARK: - Authentication
struct AuthenticateInput: ToolInput {
    let username: String
    let password: String
    
    static let requiredParameters = ["username", "password"]
    static let optionalParameters: [String: (any Sendable)] = [:]
}

// MARK: - Artist Tools
struct SearchArtistInput: ToolInput {
    let query: String
    let limit: Int
    let page: Int
    
    static let requiredParameters = ["query"]
    static let optionalParameters: [String: (any Sendable)] = [
        "limit": 10,
        "page": 1
    ]
}

struct GetArtistInfoInput: ToolInput {
    let name: String
    let autocorrect: Bool
    let username: String?
    let language: String
    
    static let requiredParameters = ["name"]
    static let optionalParameters: [String: (any Sendable)] = [
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
    static let optionalParameters: [String: (any Sendable)] = [
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
    static let optionalParameters: [String: (any Sendable)] = [
        "limit": 10,
        "page": 1
    ]
}

struct GetAlbumInfoInput: ToolInput {
    let album: String
    let artist: String
    let autocorrect: Bool
    let username: String?
    let language: String
    
    static let requiredParameters = ["album", "artist"]
    static let optionalParameters: [String: (any Sendable)] = [
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
    
    static let requiredParameters = ["query"]
    static let optionalParameters: [String: (any Sendable)] = ["artist": "", "limit": 10]
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
    static let optionalParameters: [String: (any Sendable)] = [
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
    static let optionalParameters: [String: (any Sendable)] = [
        "period": "overall",
        "limit": 10,
        "page": 1
    ]
}

// MARK: - Scrobble Tools
struct ScrobbleTrackInput: ToolInput {
    let artist: String
    let track: String
    let album: String?
    let timestamp: Int?
    let duration: Int?
    
    static let requiredParameters = ["artist", "track"]
    static let optionalParameters: [String: (any Sendable)] = [
        "album": "",
        "timestamp": 0,
        "duration": 0
    ]
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
