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
    
    // MARK: - Authentication Result Formatters
    
    static func formatAuthenticationResult(_ success: Bool, username: String? = nil) -> [String: Any] {
        var result: [String: Any] = ["authenticated": success]
        
        if let username = username {
            result["username"] = username
        }
        
        result["timestamp"] = Date().timeIntervalSince1970
        
        return result
    }
}
