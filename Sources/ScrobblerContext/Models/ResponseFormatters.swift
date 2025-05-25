//
//  ResponseFormatters.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 17/05/25.
//

import Foundation
@preconcurrency import ScrobbleKit

/// Formatters for converting ScrobbleKit models to JSON-serializable dictionaries
struct ResponseFormatters {
    
    // MARK: - Artist Formatters
    
    static func format(_ artists: [SBKArtist]) -> [String: Any] {
        let formattedArtists = artists.map(format)
        return ["artists": formattedArtists]
    }
    
    static func format(_ artist: SBKArtist) -> [String: Any] {
        var result: [String: Any] = [
            "name": artist.name,
            "url": artist.url?.absoluteString ?? ""
        ]
        
        if let listeners = artist.listeners {
            result["listeners"] = listeners
        }
        
        if let playcount = artist.playcount {
            result["playcount"] = playcount
        }
        
        if let imageURL = artist.image?.largestSize?.absoluteString {
            result["image"] = imageURL
        }
        
        if let musicBrainzID = artist.musicBrainzID {
            result["mbid"] = musicBrainzID.uuidString
        }
        
        if let similarArtists = artist.similarArtists, !similarArtists.isEmpty {
            result["similar_artists"] = similarArtists.map { $0.name }
        }
        
        if let tags = artist.tags, !tags.isEmpty {
            result["tags"] = tags.map { $0.name }
        }
        
        if let bio = artist.wiki?.summary {
            result["bio"] = bio
        }
        
        return result
    }
    
    static func format(_ similarArtists: [SBKSimilarArtist]) -> [String: Any] {
        let formattedArtists = similarArtists.map { similarArtist -> [String: Any] in
            var artistDict = format(similarArtist.artist)
            
            if let match = similarArtist.match {
                artistDict["match"] = match
            }
            
            return artistDict
        }
        
        return ["similar_artists": formattedArtists]
    }
    
    // MARK: - Album Formatters
    
    static func format(_ albums: [SBKAlbum]) -> [String: Any] {
        let formattedAlbums = albums.map(format)
        return ["albums": formattedAlbums]
    }
    
    static func format(_ album: SBKAlbum) -> [String: Any] {
        var result: [String: Any] = [
            "name": album.name,
            "artist": album.artist,
            "url": album.url?.absoluteString ?? ""
        ]
        
        if let listeners = album.listeners {
            result["listeners"] = listeners
        }
        
        if let playcount = album.playcount {
            result["playcount"] = playcount
        }
        
        if let imageURL = album.artwork?.largestSize?.absoluteString {
            result["image"] = imageURL
        }
        
        if let musicBrainzID = album.musicBrainzID {
            result["mbid"] = musicBrainzID.uuidString
        }
        
        if !album.tracklist.isEmpty {
            result["tracks"] = album.tracklist.map { track -> [String: Any] in
                var trackDict: [String: Any] = [
                    "name": track.name,
                    "artist": track.artist.name
                ]
                
                if let duration = track.duration {
                    trackDict["duration"] = duration
                }
                
                if let url = track.url {
                    trackDict["url"] = url.absoluteString
                }
                
                return trackDict
            }
        }
        
        if !album.tags.isEmpty {
            result["tags"] = album.tags.map { $0.name }
        }
        
        if let wiki = album.wiki?.summary {
            result["wiki"] = wiki
        }
        
        return result
    }
    
    // MARK: - Track Formatters
    
    static func format(_ tracks: [SBKTrack]) -> [String: Any] {
        let formattedTracks = tracks.map(format)
        return ["tracks": formattedTracks]
    }
    
    static func formatSimilarTracks(_ similarTracks: [SBKSimilarTrack]) -> [String: Any] {
        let formattedTracks = similarTracks.map { similarTrack -> [String: Any] in
            var trackDict = format(similarTrack.track)
            
            if let match = similarTrack.match {
                trackDict["match"] = match
            }
            
            return trackDict
        }
        
        return ["similar_tracks": formattedTracks]
    }
    
    static func format(_ track: SBKTrack) -> [String: Any] {
        var result: [String: Any] = [
            "name": track.name,
            "artist": track.artist.name,
            "url": track.url?.absoluteString ?? ""
        ]
        
        if let listeners = track.listeners {
            result["listeners"] = listeners
        }
        
        if let playcount = track.playcount {
            result["playcount"] = playcount
        }
        
        if let duration = track.duration {
            result["duration"] = duration
        }
        
        if let imageURL = track.artwork?.largestSize?.absoluteString {
            result["image"] = imageURL
        }
        
        if let musicBrainzID = track.musicBrainzID {
            result["mbid"] = musicBrainzID.uuidString
        }
        
        return result
    }
    
    // MARK: - Tag Formatters
    
    static func format(_ tags: [SBKTag]) -> [String: Any] {
        let formattedTags = tags.map { tag -> [String: Any] in
            var tagDict: [String: Any] = [
                "name": tag.name,
                "url": tag.url?.absoluteString ?? ""
            ]
            
            if let count = tag.count {
                tagDict["count"] = count
            }
            
            return tagDict
        }
        
        return ["tags": formattedTags]
    }
    
    // MARK: - Artist Correction Formatters
    
    static func formatArtistCorrection(_ artist: SBKArtist?) -> [String: Any] {
        if let correctedArtist = artist {
            return [
                "corrected": true,
                "corrected_artist": format(correctedArtist)
            ]
        } else {
            return [
                "corrected": false,
                "message": "No correction available"
            ]
        }
    }
    
    // MARK: - Tag Operation Result Formatters
    
    static func formatTagOperationResult(success: Bool, operation: String, artist: String, tags: [String]? = nil, tag: String? = nil) -> [String: Any] {
        var result: [String: Any] = [
            "success": success,
            "operation": operation,
            "artist": artist,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let tags = tags {
            result["tags"] = tags
        }
        
        if let tag = tag {
            result["tag"] = tag
        }
        
        return result
    }
    
    // MARK: - User Data Formatters
    
    static func format(_ recentTracks: SBKSearchResult<SBKScrobbledTrack>) -> [String: Any] {
        let formattedTracks = recentTracks.results.map { scrobbledTrack -> [String: Any] in
            var trackDict = format(scrobbledTrack.track)
            
            if let date = scrobbledTrack.date {
                trackDict["scrobbled_at"] = date.timeIntervalSince1970
                trackDict["scrobbled_date"] = ISO8601DateFormatter().string(from: date)
            }
            
            return trackDict
        }
        
        return [
            "recent_tracks": formattedTracks,
            "metadata": formatSearchMetadata(recentTracks)
        ]
    }
    
    static func format(_ topArtists: SBKSearchResult<SBKArtist>) -> [String: Any] {
        let formattedArtists = topArtists.results.map(format)
        
        return [
            "top_artists": formattedArtists,
            "metadata": formatSearchMetadata(topArtists)
        ]
    }
    
    static func format(_ topTracks: SBKSearchResult<SBKTrack>) -> [String: Any] {
        let formattedTracks = topTracks.results.map(format)
        
        return [
            "top_tracks": formattedTracks,
            "metadata": formatSearchMetadata(topTracks)
        ]
    }
    
    static func format(_ users: [SBKUser]) -> [String: Any] {
        let formattedUsers = users.map(formatUserInfo)
        return ["friends": formattedUsers]
    }
    
    static func format(_ lovedTracks: SBKLovedTracks) -> [String: Any] {
        let formattedTracks = lovedTracks.tracks.map { lovedTrack -> [String: Any] in
            var trackDict = format(lovedTrack.track)
            
            if let date = lovedTrack.date {
                trackDict["loved_at"] = date.timeIntervalSince1970
                trackDict["loved_date"] = ISO8601DateFormatter().string(from: date)
            }
            
            return trackDict
        }
        
        return [
            "loved_tracks": formattedTracks,
            "metadata": [
                "page": lovedTracks.searchAttributes.page,
                "per_page": lovedTracks.searchAttributes.perPage,
                "total_pages": lovedTracks.searchAttributes.totalPages,
                "total": lovedTracks.searchAttributes.total
            ]
        ]
    }
    
    static func format(_ topAlbums: SBKSearchResult<SBKAlbum>) -> [String: Any] {
        let formattedAlbums = topAlbums.results.map(format)
        
        return [
            "top_albums": formattedAlbums,
            "metadata": formatSearchMetadata(topAlbums)
        ]
    }
    
    static func format(_ topTags: SBKSearchResult<SBKTag>) -> [String: Any] {
        let formattedTags = topTags.results.map { tag -> [String: Any] in
            var tagDict: [String: Any] = [
                "name": tag.name,
                "url": tag.url?.absoluteString ?? ""
            ]
            
            if let count = tag.count {
                tagDict["count"] = count
            }
            
            return tagDict
        }
        
        return [
            "top_tags": formattedTags,
            "metadata": formatSearchMetadata(topTags)
        ]
    }
    
    // MARK: - Helper Methods
    
    private static func formatSearchMetadata<T>(_ searchResult: SBKSearchResult<T>) -> [String: Any] {
        return [
            "page": searchResult.page,
            "per_page": searchResult.perPage,
            "total_pages": searchResult.totalPages,
            "total": searchResult.total
        ]
    }
    
    // MARK: - Scrobble Result Formatters
    
    static func format(_ scrobbleSuccess: Bool) -> [String: Any] {
        return [
            "scrobbled": scrobbleSuccess,
            "timestamp": Date().timeIntervalSince1970
        ]
    }
    
    static func formatScrobbleResult(success: Bool, artist: String, track: String, album: String? = nil) -> [String: Any] {
        var result: [String: Any] = [
            "scrobbled": success,
            "artist": artist,
            "track": track,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let album = album {
            result["album"] = album
        }
        
        return result
    }
    
    static func formatNowPlayingResult(success: Bool, artist: String, track: String, album: String? = nil) -> [String: Any] {
        var result: [String: Any] = [
            "now_playing_updated": success,
            "artist": artist,
            "track": track,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if let album = album {
            result["album"] = album
        }
        
        return result
    }
    
    static func formatLoveResult(loved: Bool, artist: String, track: String) -> [String: Any] {
        return [
            "loved": loved,
            "artist": artist,
            "track": track,
            "action": loved ? "loved" : "unloved",
            "timestamp": Date().timeIntervalSince1970
        ]
    }
    
    // MARK: - Authentication Result Formatters
    
    static func formatAuthenticationResult(_ success: Bool, username: String? = nil) -> [String: Any] {
        var result: [String: Any] = ["authenticated": success]
        
        if let username = username {
            result["username"] = username
        }
        
        result["timestamp"] = Date().timeIntervalSince1970
        
        return result
    }
    
    // MARK: - User Info Formatters
    
    static func formatUserInfo(_ user: SBKUser) -> [String: Any] {
        var result: [String: Any] = [
            "username": user.username,
            "url": user.url,
            "playcount": user.playcount,
            "is_pro": user.isPro,
            "member_since": user.memberSince.timeIntervalSince1970,
            "member_since_date": ISO8601DateFormatter().string(from: user.memberSince)
        ]
        
        if let realName = user.realName {
            result["real_name"] = realName
        }
        
        if let country = user.country {
            result["country"] = country
        }
        
        if let age = user.age {
            result["age"] = age
        }
        
        if let gender = user.gender {
            result["gender"] = gender
        }
        
        if let artistCount = user.artistCount {
            result["artist_count"] = artistCount
        }
        
        if let playlistsCount = user.playlistsCount {
            result["playlists_count"] = playlistsCount
        }
        
        if let imageURL = user.image?.largestSize?.absoluteString {
            result["image"] = imageURL
        }
        
        if let type = user.type {
            result["account_type"] = type
        }
        
        return result
    }
}
