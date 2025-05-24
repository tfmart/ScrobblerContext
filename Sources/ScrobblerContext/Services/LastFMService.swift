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

/// Core service wrapper for ScrobbleKit
final class LastFMService: Sendable {
    let manager: SBKManager
    let logger = Logger(label: "com.lastfm.mcp-server.service")
    
    init(apiKey: String, secretKey: String) {
        self.manager = SBKManager(apiKey: apiKey, secret: secretKey)
        logger.info("LastFM service initialized")
    }
    
    func authenticate(username: String, password: String) async throws -> SBKSessionResponseInfo {
        do {
            let session = try await manager.startSession(username: username, password: password)
            logger.info("Successfully authenticated as \(session.name)")
            return session
        } catch {
            logger.error("Authentication failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Artist Services
    
    func searchArtist(query: String, limit: Int = 10) async throws -> [SBKArtist] {
        logger.info("Searching for artist: \(query) (limit: \(limit))")
        return try await manager.search(artist: query, limit: limit)
    }
    
    func getArtistInfo(name: String) async throws -> SBKArtist {
        logger.info("Getting artist info for: \(name)")
        return try await manager.getInfo(forArtist: .artistName(name))
    }
    
    func getSimilarArtists(name: String, limit: Int = 10) async throws -> [SBKSimilarArtist] {
        logger.info("Getting similar artists for: \(name) (limit: \(limit))")
        return try await manager.getSimilarArtists(.artistName(name), limit: limit)
    }
    
    // MARK: - Album Services
    
    func searchAlbum(query: String, limit: Int = 10) async throws -> [SBKAlbum] {
        logger.info("Searching for album: \(query) (limit: \(limit))")
        return try await manager.search(album: query, limit: limit)
    }
    
    func getAlbumInfo(album: String, artist: String) async throws -> SBKAlbum {
        logger.info("Getting album info for: \(album) by \(artist)")
        return try await manager.getInfo(forAlbum: .albumArtist(album: album, artist: artist))
    }
    
    // MARK: - Track Services
    
    func searchTrack(query: String, artist: String? = nil, limit: Int = 10) async throws -> [SBKTrack] {
        if let artist = artist {
            logger.info("Searching for track: \(query) by \(artist) (limit: \(limit))")
        } else {
            logger.info("Searching for track: \(query) (limit: \(limit))")
        }
        return try await manager.search(track: query, artist: artist, limit: limit)
    }
    
    func getTrackInfo(track: String, artist: String) async throws -> SBKTrack {
        logger.info("Getting track info for: \(track) by \(artist)")
        return try await manager.getInfo(forTrack: track, artist: artist)
    }
    
    func getSimilarTracks(track: String, artist: String, limit: Int = 10) async throws -> [SBKSimilarTrack] {
        logger.info("Getting similar tracks for: \(track) by \(artist) (limit: \(limit))")
        return try await manager.getSimilarTracks(.trackInfo(track, artist: artist), limit: limit)
    }
    
    // MARK: - User Services
    
    func getUserRecentTracks(user: String, limit: Int = 10) async throws -> SBKSearchResult<SBKScrobbledTrack> {
        logger.info("Getting recent tracks for user: \(user) (limit: \(limit))")
        return try await manager.getRecentTracks(fromUser: user, limit: limit)
    }
    
    func getUserTopArtists(user: String, limit: Int = 10) async throws -> SBKSearchResult<SBKArtist> {
        logger.info("Getting top artists for user: \(user) (limit: \(limit))")
        return try await manager.getTopArtists(forUser: user, limit: limit)
    }
    
    func getUserTopTracks(user: String, limit: Int = 10) async throws -> SBKSearchResult<SBKTrack> {
        logger.info("Getting top tracks for user: \(user) (limit: \(limit))")
        return try await manager.getTopTracks(forUser: user, limit: limit)
    }
    
    // MARK: - Scrobbling Services
    
    func scrobbleTrack(artist: String, track: String, album: String? = nil) async throws -> Bool {
        guard await isAuthenticated() else {
            logger.error("Cannot scrobble: User is not authenticated")
            throw ToolError.authenticationRequired
        }
        
        logger.info("Scrobbling track: \(track) by \(artist)")
        
        let trackToScrobble = SBKTrackToScrobble(
            artist: artist,
            track: track,
            timestamp: Date(),
            album: album
        )
        
        let response = try await manager.scrobble(tracks: [trackToScrobble])
        let success = response.isCompletelySuccessful
        
        if success {
            logger.info("Successfully scrobbled: \(track) by \(artist)")
        } else {
            logger.warning("Scrobble partially failed for: \(track) by \(artist)")
        }
        
        return success
    }
    
    func updateNowPlaying(artist: String, track: String, album: String? = nil) async throws -> Bool {
        guard await isAuthenticated() else {
            logger.error("Cannot update now playing: User is not authenticated")
            throw ToolError.authenticationRequired
        }
        
        logger.info("Updating now playing: \(track) by \(artist)")
        
        do {
            _ = try await manager.updateNowPlaying(
                artist: artist,
                track: track,
                album: album
            )
            logger.info("Successfully updated now playing: \(track) by \(artist)")
            return true
        } catch {
            logger.error("Failed to update now playing: \(error)")
            throw error
        }
    }
    
    // MARK: - Utility Methods
    
    func validateService() async throws {
        logger.info("Validating Last.fm service connection")
        do {
            // Try to get top tags - this doesn't require authentication
            _ = try await manager.getTopTags()
            logger.info("Service validation successful")
        } catch {
            logger.error("Service validation failed: \(error)")
            throw ToolError.lastFMError("Failed to connect to Last.fm service: \(error.localizedDescription)")
        }
    }
}
