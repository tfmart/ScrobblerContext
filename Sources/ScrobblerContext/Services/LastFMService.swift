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

/// Core service wrapper for ScrobbleKit with enhanced authentication
final class LastFMService: Sendable {
    let manager: SBKManager
    let logger = Logger(label: "com.lastfm.mcp-server.service")
    
    // Store API credentials for OAuth flow
    private let apiKey: String
    private let secretKey: String
    
    // Session management - using actor for thread safety
    private let sessionManager = SessionManager()
    
    init(apiKey: String, secretKey: String) {
        self.apiKey = apiKey
        self.secretKey = secretKey
        self.manager = SBKManager(apiKey: apiKey, secret: secretKey)
        logger.info("LastFM service initialized")
    }
    
    // MARK: - Public API Access
    
    /// Get API key for OAuth URL generation
    func getAPIKey() -> String {
        return apiKey
    }
    
    // MARK: - Enhanced Authentication Methods
    
    /// Set session key directly (for OAuth flow)
    func setSessionKey(_ sessionKey: String) async throws {
        await sessionManager.setSessionKey(sessionKey)
        
        // Set the session key in ScrobbleKit manager
        manager.setSessionKey(sessionKey)
        
        // Verify the session works by getting user info
        do {
            let userInfo = try await manager.getInfo(forUser: nil) // nil gets current authenticated user
            await sessionManager.setUsername(userInfo.username)
            logger.info("Session key set successfully for user: \(userInfo.username)")
        } catch {
            // Clear invalid session
            await sessionManager.clearSession()
            manager.signOut()
            logger.error("Invalid session key provided: \(error)")
            throw ToolError.authenticationFailed("Invalid session key: \(error.localizedDescription)")
        }
    }
    
    /// Check if user is currently authenticated
    func isAuthenticated() async -> Bool {
        guard let sessionKey = await sessionManager.getSessionKey(), !sessionKey.isEmpty else {
            return false
        }
        
        // Verify session is still valid by making a simple API call
        do {
            _ = try await manager.getInfo(forUser: nil)
            return true
        } catch {
            logger.warning("Session appears to be invalid: \(error)")
            await clearSession()
            return false
        }
    }
    
    /// Get current authenticated username
    func getCurrentUsername() async -> String? {
        guard await isAuthenticated() else { return nil }
        return await sessionManager.getUsername()
    }
    
    /// Clear current session
    func clearSession() async {
        await sessionManager.clearSession()
        manager.signOut()
        logger.info("Session cleared")
    }
    
    // MARK: - OAuth Helper Methods
    
    /// Exchange OAuth token for session key
    func exchangeTokenForSession(token: String) async throws -> String {
        // Create signature for API call
        let params = [
            "api_key": apiKey,
            "method": "auth.getSession",
            "token": token
        ]
        
        let signature = createAPISignature(params: params, secret: secretKey)
        
        // Make API request
        let url = "https://ws.audioscrobbler.com/2.0/"
        var urlComponents = URLComponents(string: url)!
        
        urlComponents.queryItems = [
            URLQueryItem(name: "method", value: "auth.getSession"),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "token", value: token),
            URLQueryItem(name: "api_sig", value: signature),
            URLQueryItem(name: "format", value: "json")
        ]
        
        guard let requestURL = urlComponents.url else {
            throw ToolError.authenticationFailed("Failed to construct API request URL")
        }
        
        logger.info("Requesting session key from Last.fm API...")
        
        let (data, response) = try await URLSession.shared.data(from: requestURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ToolError.authenticationFailed("Last.fm API request failed with status: \((response as? HTTPURLResponse)?.statusCode ?? -1)")
        }
        
        // Parse JSON response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ToolError.authenticationFailed("Invalid JSON response from Last.fm API")
        }
        
        // Check for API error
        if let error = json["error"] as? Int,
           let message = json["message"] as? String {
            throw ToolError.authenticationFailed("Last.fm API error \(error): \(message)")
        }
        
        // Extract session key
        guard let session = json["session"] as? [String: Any],
              let sessionKey = session["key"] as? String,
              let username = session["name"] as? String else {
            throw ToolError.authenticationFailed("Invalid session data in Last.fm API response")
        }
        
        // Store username for later use
        await sessionManager.setUsername(username)
        
        logger.info("Successfully obtained session key for user: \(username)")
        return sessionKey
    }
    
    /// Create API signature for Last.fm requests
    private func createAPISignature(params: [String: String], secret: String) -> String {
        // Sort parameters alphabetically and concatenate
        let sortedParams = params.sorted { $0.key < $1.key }
        let paramString = sortedParams.map { "\($0.key)\($0.value)" }.joined()
        let stringToSign = paramString + secret
        
        // Generate MD5 hash
        return stringToSign.md5Hash
    }
    
    // MARK: - Artist Services
    
    func searchArtist(query: String, limit: Int = 10, page: Int = 1) async throws -> [SBKArtist] {
        logger.info("Searching for artist: \(query) (limit: \(limit), page: \(page))")
        return try await manager.search(artist: query, limit: limit, page: page)
    }
    
    func getArtistInfo(name: String, autocorrect: Bool = true, username: String? = nil, language: String = "en") async throws -> SBKArtist {
        logger.info("Getting artist info for: \(name) (autocorrect: \(autocorrect), username: \(username ?? "none"), language: \(language))")
        
        // Convert string language code to SBKLanguageCode
        let languageCode = SBKLanguageCode(rawValue: language) ?? .english
        
        return try await manager.getInfo(
            forArtist: .artistName(name),
            autocorrect: autocorrect,
            username: username,
            language: languageCode
        )
    }
    
    func getSimilarArtists(name: String, limit: Int = 10, autocorrect: Bool = true) async throws -> [SBKSimilarArtist] {
        logger.info("Getting similar artists for: \(name) (limit: \(limit), autocorrect: \(autocorrect))")
        return try await manager.getSimilarArtists(.artistName(name), limit: limit, autoCorrect: autocorrect)
    }
    
    func addTagsToArtist(artist: String, tags: [String]) async throws -> Bool {
        guard await isAuthenticated() else {
            logger.error("Cannot add tags to artist: User is not authenticated")
            throw ToolError.authenticationRequired
        }
        
        logger.info("Adding tags to artist: \(artist), tags: \(tags)")
        return try await manager.addTags(toArtist: artist, tags: tags)
    }
    
    func getCorrectedArtistName(artist: String) async throws -> SBKArtist? {
        logger.info("Getting corrected artist name for: \(artist)")
        return try await manager.getCorrectedArtistName(artist)
    }
    
    func getArtistTags(name: String, user: String? = nil, autocorrect: Bool = true) async throws -> [SBKTag] {
        logger.info("Getting tags for artist: \(name) (user: \(user ?? "all"), autocorrect: \(autocorrect))")
        return try await manager.getTags(forArtist: .artistName(name), user: user, autocorrect: autocorrect)
    }
    
    func getArtistTopAlbums(name: String, limit: Int = 50, page: Int = 1, autocorrect: Bool = true) async throws -> [SBKAlbum] {
        logger.info("Getting top albums for artist: \(name) (limit: \(limit), page: \(page), autocorrect: \(autocorrect))")
        return try await manager.getTopAlbums(forArtist: .artistName(name), limit: limit, page: page, autoCorrect: autocorrect)
    }
    
    func getArtistTopTracks(name: String, limit: Int = 50, page: Int = 1, autocorrect: Bool = true) async throws -> [SBKTrack] {
        logger.info("Getting top tracks for artist: \(name) (limit: \(limit), page: \(page), autocorrect: \(autocorrect))")
        return try await manager.getArtistTopTracks(.artistName(name), limit: limit, page: page, autoCorrect: autocorrect)
    }
    
    func removeTagFromArtist(artist: String, tag: String) async throws -> Bool {
        guard await isAuthenticated() else {
            logger.error("Cannot remove tag from artist: User is not authenticated")
            throw ToolError.authenticationRequired
        }
        
        logger.info("Removing tag '\(tag)' from artist: \(artist)")
        return try await manager.removeTag(fromArtist: artist, tag: tag)
    }
    
    // MARK: - Album Services
    
    func searchAlbum(query: String, limit: Int = 10, page: Int = 1) async throws -> [SBKAlbum] {
        logger.info("Searching for album: \(query) (limit: \(limit), page: \(page))")
        return try await manager.search(album: query, page: page, limit: limit)
    }
    
    func getAlbumInfo(album: String, artist: String, autocorrect: Bool = true, username: String? = nil, language: String = "en") async throws -> SBKAlbum {
        logger.info("Getting album info for: \(album) by \(artist) (autocorrect: \(autocorrect), username: \(username ?? "none"), language: \(language))")
        
        // Convert string language code to SBKLanguageCode
        let languageCode = SBKLanguageCode(rawValue: language) ?? .english
        
        return try await manager.getInfo(
            forAlbum: .albumArtist(album: album, artist: artist),
            autoCorrect: autocorrect,
            username: username,
            languageCode: languageCode
        )
    }
    
    func addTagsToAlbum(album: String, artist: String, tags: [String]) async throws -> Bool {
        guard await isAuthenticated() else {
            logger.error("Cannot add tags to album: User is not authenticated")
            throw ToolError.authenticationRequired
        }
        
        logger.info("Adding tags to album: \(album) by \(artist), tags: \(tags)")
        return try await manager.addTags(toAlbum: album, artist: artist, tags: tags)
    }
    
    func getAlbumTags(album: String, artist: String, autocorrect: Bool = true, username: String? = nil) async throws -> [SBKTag] {
        logger.info("Getting tags for album: \(album) by \(artist) (autocorrect: \(autocorrect), username: \(username ?? "none"))")
        return try await manager.getTags(forAlbum: .albumArtist(album: album, artist: artist), autoCorrect: autocorrect, username: username)
    }
    
    func getAlbumTopTags(album: String, artist: String, autocorrect: Bool = true) async throws -> [SBKTag] {
        logger.info("Getting top tags for album: \(album) by \(artist) (autocorrect: \(autocorrect))")
        return try await manager.getTopTags(forAlbum: .albumArtist(album: album, artist: artist), autoCorrect: autocorrect)
    }
    
    func removeTagFromAlbum(album: String, artist: String, tag: String) async throws -> Bool {
        guard await isAuthenticated() else {
            logger.error("Cannot remove tag from album: User is not authenticated")
            throw ToolError.authenticationRequired
        }
        
        logger.info("Removing tag '\(tag)' from album: \(album) by \(artist)")
        return try await manager.removeTag(fromAlbum: album, artist: artist, tag: tag)
    }
    
    // MARK: - Track Services
    
    func searchTrack(query: String, artist: String? = nil, limit: Int = 10, page: Int = 1) async throws -> [SBKTrack] {
        if let artist = artist {
            logger.info("Searching for track: \(query) by \(artist) (limit: \(limit), page: \(page))")
        } else {
            logger.info("Searching for track: \(query) (limit: \(limit), page: \(page))")
        }
        // Note: ScrobbleKit uses page: 0 as default, but we'll convert from 1-based to 0-based
        let apiPage = max(0, page - 1)
        return try await manager.search(track: query, artist: artist, limit: limit, page: apiPage)
    }
    
    func getTrackInfo(track: String, artist: String, username: String? = nil, autocorrect: Bool = false, language: String = "en") async throws -> SBKTrack {
        logger.info("Getting track info for: \(track) by \(artist) (username: \(username ?? "none"), autocorrect: \(autocorrect), language: \(language))")
        
        // Convert string language code to SBKLanguageCode
        let languageCode = SBKLanguageCode(rawValue: language) ?? .english
        
        return try await manager.getInfo(
            forTrack: track,
            artist: artist,
            username: username,
            autoCorrect: autocorrect,
            languageCode: languageCode
        )
    }
    
    func getSimilarTracks(track: String, artist: String, autocorrect: Bool = true, limit: Int? = nil) async throws -> [SBKSimilarTrack] {
        logger.info("Getting similar tracks for: \(track) by \(artist) (autocorrect: \(autocorrect), limit: \(limit?.description ?? "default"))")
        return try await manager.getSimilarTracks(.trackInfo(track, artist: artist), autoCorrect: autocorrect, limit: limit)
    }
    
    func getCorrectedTrackInfo(track: String, artist: String) async throws -> SBKTrack? {
        logger.info("Getting corrected track info for: \(track) by \(artist)")
        return try await manager.getCorrectedTrackInfo(for: track, by: artist)
    }
    
    func getTrackTags(track: String, artist: String, autocorrect: Bool = true, username: String? = nil) async throws -> [SBKTag] {
        logger.info("Getting tags for track: \(track) by \(artist) (autocorrect: \(autocorrect), username: \(username ?? "none"))")
        return try await manager.getTags(forTrack: .trackInfo(track, artist: artist), autoCorrect: autocorrect, username: username)
    }
    
    func getTrackTopTags(track: String, artist: String, autocorrect: Bool = true) async throws -> [SBKTag] {
        logger.info("Getting top tags for track: \(track) by \(artist) (autocorrect: \(autocorrect))")
        return try await manager.getTopTagsForTrack(searchMethod: .trackInfo(track, artist: artist), autoCorrect: autocorrect)
    }
    
    func addTagsToTrack(track: String, artist: String, tags: [String]) async throws -> Bool {
        guard await isAuthenticated() else {
            logger.error("Cannot add tags to track: User is not authenticated")
            throw ToolError.authenticationRequired
        }
        
        logger.info("Adding tags to track: \(track) by \(artist), tags: \(tags)")
        return try await manager.addTags(toTrack: track, artist: artist, tags: tags)
    }
    
    func removeTagFromTrack(track: String, artist: String, tag: String) async throws -> Bool {
        guard await isAuthenticated() else {
            logger.error("Cannot remove tag from track: User is not authenticated")
            throw ToolError.authenticationRequired
        }
        
        logger.info("Removing tag '\(tag)' from track: \(track) by \(artist)")
        return try await manager.removeTag(fromTrack: track, artist: artist, tag: tag)
    }
    
    // MARK: - User Services
    
    func getUserRecentTracks(
        user: String,
        limit: Int = 50,
        page: Int = 1,
        startDate: Date? = nil,
        extended: Bool = false,
        endDate: Date? = nil
    ) async throws -> SBKSearchResult<SBKScrobbledTrack> {
        logger.info("Getting recent tracks for user: \(user) (limit: \(limit), page: \(page))")
        
        if let startDate = startDate {
            logger.info("Start date filter: \(startDate)")
        }
        if let endDate = endDate {
            logger.info("End date filter: \(endDate)")
        }
        if extended {
            logger.info("Extended data requested")
        }
        
        return try await manager.getRecentTracks(
            fromUser: user,
            limit: limit,
            page: page,
            startDate: startDate,
            extended: extended,
            endDate: endDate
        )
    }
    
    func getUserTopArtists(user: String, period: String = "overall", limit: Int = 10, page: Int = 1) async throws -> SBKSearchResult<SBKArtist> {
        logger.info("Getting top artists for user: \(user) (period: \(period), limit: \(limit), page: \(page))")
        
        // Convert string period to SBKSearchPeriod
        let searchPeriod = convertStringToPeriod(period)
        
        return try await manager.getTopArtists(forUser: user, period: searchPeriod, limit: limit, page: page)
    }
    
    func getUserTopTracks(user: String, period: String = "overall", limit: Int = 10, page: Int = 1) async throws -> SBKSearchResult<SBKTrack> {
        logger.info("Getting top tracks for user: \(user) (period: \(period), limit: \(limit), page: \(page))")
        
        // Convert string period to SBKSearchPeriod
        let searchPeriod = convertStringToPeriod(period)
        
        return try await manager.getTopTracks(forUser: user, period: searchPeriod, limit: limit, page: page)
    }
    
    // MARK: - Helper Methods
    
    private func convertStringToPeriod(_ period: String) -> SBKSearchPeriod {
        switch period.lowercased() {
        case "7day", "7days":
            return .sevenDays
        case "1month", "1months":
            return .oneMonth
        case "3month", "3months":
            return .threeMonths
        case "6month", "6months":
            return .sixMonths
        case "12month", "12months":
            return .twelveMonths
        case "overall":
            return .overall
        default:
            logger.warning("Unknown period '\(period)', defaulting to 'overall'")
            return .overall
        }
    }
    
    func getUserInfo(username: String) async throws -> SBKUser {
        logger.info("Getting user info for: \(username)")
        return try await manager.getInfo(forUser: username)
    }
    
    func getUserFriends(user: String, recentTracks: Bool = false, limit: Int = 50, page: Int = 1) async throws -> [SBKUser] {
        logger.info("Getting friends for user: \(user) (recentTracks: \(recentTracks), limit: \(limit), page: \(page))")
        return try await manager.getFriends(for: user, recentTracks: recentTracks, limit: limit, page: page)
    }
    
    func getUserLovedTracks(user: String, limit: Int = 50, page: Int = 1) async throws -> SBKLovedTracks {
        logger.info("Getting loved tracks for user: \(user) (limit: \(limit), page: \(page))")
        return try await manager.getLovedTracks(fromUser: user, limit: limit, page: page)
    }
    
    func getUserPersonalTagsForArtists(user: String, tag: String, limit: Int = 50, page: Int = 1) async throws -> SBKSearchResult<SBKArtist> {
        logger.info("Getting personal tags for artists from user: \(user), tag: \(tag) (limit: \(limit), page: \(page))")
        return try await manager.getPersonalTagsForArtists(fromUser: user, tag: tag, limit: limit, page: page)
    }
    
    func getUserTopAlbums(user: String, period: String = "overall", limit: Int = 50, page: Int = 1) async throws -> SBKSearchResult<SBKAlbum> {
        logger.info("Getting top albums for user: \(user) (period: \(period), limit: \(limit), page: \(page))")
        
        // Convert string period to SBKSearchPeriod
        let searchPeriod = convertStringToPeriod(period)
        
        return try await manager.getTopAlbums(forUser: user, period: searchPeriod, limit: limit, page: page)
    }
    
    func getUserTopTags(user: String, limit: Int? = nil) async throws -> SBKSearchResult<SBKTag> {
        logger.info("Getting top tags for user: \(user) (limit: \(limit?.description ?? "default"))")
        return try await manager.getTopTags(forUser: user, limit: limit)
    }
    
    // MARK: - Love/Unlove Services
    
    func loveTrack(track: String, artist: String) async throws {
        guard await isAuthenticated() else {
            logger.error("Cannot love track: User is not authenticated")
            throw ToolError.authenticationRequired
        }
        
        logger.info("Loving track: \(track) by \(artist)")
        try await manager.loveTrack(track: track, artist: artist)
        logger.info("Successfully loved: \(track) by \(artist)")
    }
    
    func unloveTrack(track: String, artist: String) async throws {
        guard await isAuthenticated() else {
            logger.error("Cannot unlove track: User is not authenticated")
            throw ToolError.authenticationRequired
        }
        
        logger.info("Unloving track: \(track) by \(artist)")
        try await manager.unloveTrack(track: track, artist: artist)
        logger.info("Successfully unloved: \(track) by \(artist)")
    }
    
    // MARK: - Scrobbling Services
    
    func scrobbleTrack(
        artist: String,
        track: String,
        timestamp: Date? = nil,
        album: String? = nil,
        albumArtist: String? = nil,
        trackNumber: Int? = nil,
        duration: Int? = nil,
        chosenByUser: Bool? = nil,
        mbid: String? = nil
    ) async throws -> Bool {
        guard await isAuthenticated() else {
            logger.error("Cannot scrobble: User is not authenticated")
            throw ToolError.authenticationRequired
        }
        
        logger.info("Scrobbling track: \(track) by \(artist)")
        
        let trackToScrobble = SBKTrackToScrobble(
            artist: artist,
            track: track,
            timestamp: timestamp ?? Date(),
            album: album,
            albumArtist: albumArtist,
            trackNumber: trackNumber,
            duration: duration,
            chosenByUser: chosenByUser,
            mbid: mbid
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
    
    func scrobbleMultipleTracks(_ tracks: [SBKTrackToScrobble]) async throws -> SBKScrobbleResponse {
        guard await isAuthenticated() else {
            logger.error("Cannot scrobble multiple tracks: User is not authenticated")
            throw ToolError.authenticationRequired
        }
        
        logger.info("Scrobbling \(tracks.count) tracks")
        
        let response = try await manager.scrobble(tracks: tracks)
        
        let successCount = response.acceptedCount
        let failureCount = tracks.count - successCount
        
        if response.isCompletelySuccessful {
            logger.info("Successfully scrobbled all \(tracks.count) tracks")
        } else if successCount > 0 {
            logger.warning("Partially successful: \(successCount) succeeded, \(failureCount) failed")
        } else {
            logger.error("Failed to scrobble all \(tracks.count) tracks")
        }
        
        return response
    }
    
    func updateNowPlaying(
        artist: String,
        track: String,
        album: String? = nil,
        trackNumber: Int? = nil,
        context: String? = nil,
        mbid: String? = nil,
        duration: Int? = nil,
        albumArtist: String? = nil
    ) async throws -> Bool {
        guard await isAuthenticated() else {
            logger.error("Cannot update now playing: User is not authenticated")
            throw ToolError.authenticationRequired
        }
        
        logger.info("Updating now playing: \(track) by \(artist)")
        
        do {
            _ = try await manager.updateNowPlaying(
                artist: artist,
                track: track,
                album: album,
                trackNumber: trackNumber,
                context: context,
                mbid: mbid,
                duration: duration,
                albumArtist: albumArtist
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
