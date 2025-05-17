//
//  LastFMService.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 17/05/25.
//


import Foundation
import MCP
@preconcurrency import ScrobbleKit
import Logging

let logger = Logger(label: "com.lastfm.mcp-server")

// LastFM Service wrapper for ScrobbleKit
final class LastFMService: Sendable {
    private let manager: SBKManager
    private var isAuthenticated: Bool {
        return manager.sessionKey != nil
    }
    
    init(apiKey: String, secretKey: String) {
        self.manager = SBKManager(apiKey: apiKey, secret: secretKey)
        logger.info("LastFM service initialized")
        
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardError(label: label)
            handler.logLevel = .info
            return handler
        }
    }
    
    func authenticate(username: String, password: String) async throws -> Bool {
        do {
            let session = try await manager.startSession(username: username, password: password)
            logger.info("Successfully authenticated as \(session.name)")
            return true
        } catch {
            logger.error("Authentication failed: \(error)")
            throw error
        }
    }
    
    func setSessionKey(_ key: String) {
        manager.setSessionKey(key)
        logger.info("Session key set")
    }
    
    // Artist related methods
    func searchArtist(query: String, limit: Int = 10) async throws -> [SBKArtist] {
        return try await manager.search(artist: query, limit: limit)
    }
    
    func getArtistInfo(name: String) async throws -> SBKArtist {
        return try await manager.getInfo(forArtist: .artistName(name))
    }
    
    func getSimilarArtists(name: String, limit: Int = 10) async throws -> [SBKSimilarArtist] {
        return try await manager.getSimilarArtists(.artistName(name), limit: limit)
    }
    
    // Album related methods
    func searchAlbum(query: String, limit: Int = 10) async throws -> [SBKAlbum] {
        return try await manager.search(album: query, limit: limit)
    }
    
    func getAlbumInfo(album: String, artist: String) async throws -> SBKAlbum {
        return try await manager.getInfo(forAlbum: .albumArtist(album: album, artist: artist))
    }
    
    // Track related methods
    func searchTrack(query: String, artist: String? = nil, limit: Int = 10) async throws -> [SBKTrack] {
        return try await manager.search(track: query, artist: artist, limit: limit)
    }
    
    func getTrackInfo(track: String, artist: String) async throws -> SBKTrack {
        return try await manager.getInfo(forTrack: track, artist: artist)
    }
    
    // User related methods
    func getUserRecentTracks(user: String, limit: Int = 10) async throws -> SBKSearchResult<SBKScrobbledTrack> {
        return try await manager.getRecentTracks(fromUser: user, limit: limit)
    }
    
    func getUserTopArtists(user: String, limit: Int = 10) async throws -> SBKSearchResult<SBKArtist> {
        return try await manager.getTopArtists(forUser: user, limit: limit)
    }
    
    func getUserTopTracks(user: String, limit: Int = 10) async throws -> SBKSearchResult<SBKTrack> {
        return try await manager.getTopTracks(forUser: user, limit: limit)
    }
    
    // Scrobbling
    func scrobbleTrack(artist: String, track: String, album: String? = nil) async throws -> Bool {
        guard isAuthenticated else {
            logger.error("Cannot scrobble: User is not authenticated")
            throw NSError(domain: "LastFMService", code: 401, userInfo: [NSLocalizedDescriptionKey: "Authentication required"])
        }
        
        let trackToScrobble = SBKTrackToScrobble(
            artist: artist,
            track: track,
            timestamp: Date(),
            album: album
        )
        
        let response = try await manager.scrobble(tracks: [trackToScrobble])
        return response.isCompletelySuccessful
    }
}