import Foundation
import MCP
@preconcurrency import ScrobbleKit
import Logging

// Main MCP server setup
@main
struct SBKServer {
    static func main() async throws {
        // Configuration - these should come from environment variables or config file
        let apiKey = ProcessInfo.processInfo.environment["LASTFM_API_KEY"] ?? "YOUR_API_KEY"
        let secretKey = ProcessInfo.processInfo.environment["LASTFM_SECRET_KEY"] ?? "YOUR_SECRET_KEY"
        
        // Create LastFM service
        let lastFM = LastFMService(apiKey: apiKey, secretKey: secretKey)
        
        // Create server
        let server = Server(
            name: "Last.fm MCP Server",
            version: "1.0.0",
            capabilities: .init(tools: .init(listChanged: false))
        )
        
        // Create and register tools
        let tools = createTools(lastFM: lastFM)
        
        // Register tool list handler
        await server.withMethodHandler(ListTools.self) { params in
            logger.info("Listing tools")
            return ListTools.Result(tools: tools)
        }
        
        // Register tool call handler
        await server.withMethodHandler(CallTool.self) { params in
            let toolName = params.name
            logger.info("Tool call received: \(toolName)")
            
            // Log the raw arguments for debugging
            logger.info("Parameters received: \(params.arguments)")
            
            // Find the matching tool handler
            guard let result = try await executeToolCall(toolName: toolName, arguments: params.arguments, lastFM: lastFM) else {
                throw MCPError.invalidParams("Unknown tool: \(toolName)")
            }
            
            return CallTool.Result(content: [.text(.init(result))])
        }
        
        // Start server with stdio transport
        let transport = StdioTransport()
        logger.info("Starting server with stdio transport")
        try await server.start(transport: transport)
        
        // Keep the process running
        logger.info("Server started, waiting for completion")
        await server.waitUntilCompleted()
    }
    
    static func createTools(lastFM: LastFMService) -> [Tool] {
        let authenticateTool = Tool(
            name: "authenticate_user",
            description: "Authenticate with Last.fm using username and password",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "username": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username")
                    ]),
                    "password": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm password")
                    ])
                ]),
                "required": .array([.string("username"), .string("password")])
            ])
        )
        
        let searchArtistTool = Tool(
            name: "search_artist",
            description: "Search for artists on Last.fm",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "query": .object([
                        "type": .string("string"),
                        "description": .string("Artist name to search for")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Maximum number of results"),
                        "default": .int(10)
                    ])
                ]),
                "required": .array([.string("query")])
            ])
        )
        
        let getArtistInfoTool = Tool(
            name: "get_artist_info",
            description: "Get detailed information about an artist",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "name": .object([
                        "type": .string("string"),
                        "description": .string("Name of the artist")
                    ])
                ]),
                "required": .array([.string("name")])
            ])
        )
        
        let getSimilarArtistsTool = Tool(
            name: "get_similar_artists",
            description: "Get artists similar to the specified artist",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "name": .object([
                        "type": .string("string"),
                        "description": .string("Name of the artist")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Maximum number of results"),
                        "default": .int(10)
                    ])
                ]),
                "required": .array([.string("name")])
            ])
        )
        
        let searchAlbumTool = Tool(
            name: "search_album",
            description: "Search for albums on Last.fm",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "query": .object([
                        "type": .string("string"),
                        "description": .string("Album name to search for")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Maximum number of results"),
                        "default": .int(10)
                    ])
                ]),
                "required": .array([.string("query")])
            ])
        )
        
        let getAlbumInfoTool = Tool(
            name: "get_album_info",
            description: "Get detailed information about an album",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "album": .object([
                        "type": .string("string"),
                        "description": .string("Name of the album")
                    ]),
                    "artist": .object([
                        "type": .string("string"),
                        "description": .string("Name of the artist")
                    ])
                ]),
                "required": .array([.string("album"), .string("artist")])
            ])
        )
        
        let searchTrackTool = Tool(
            name: "search_track",
            description: "Search for tracks on Last.fm",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "query": .object([
                        "type": .string("string"),
                        "description": .string("Track name to search for")
                    ]),
                    "artist": .object([
                        "type": .string("string"),
                        "description": .string("Artist name to filter by")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Maximum number of results"),
                        "default": .int(10)
                    ])
                ]),
                "required": .array([.string("query")])
            ])
        )
        
        let getUserRecentTracksTool = Tool(
            name: "get_user_recent_tracks",
            description: "Get a user's recently played tracks",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "username": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Maximum number of results"),
                        "default": .int(10)
                    ])
                ]),
                "required": .array([.string("username")])
            ])
        )
        
        let getUserTopArtistsTool = Tool(
            name: "get_user_top_artists",
            description: "Get a user's top artists",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "username": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username")
                    ]),
                    "limit": .object([
                        "type": .string("integer"),
                        "description": .string("Maximum number of results"),
                        "default": .int(10)
                    ])
                ]),
                "required": .array([.string("username")])
            ])
        )
        
        let scrobbleTrackTool = Tool(
            name: "scrobble_track",
            description: "Scrobble a track to the authenticated user's Last.fm profile",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "artist": .object([
                        "type": .string("string"),
                        "description": .string("Artist name")
                    ]),
                    "track": .object([
                        "type": .string("string"),
                        "description": .string("Track name")
                    ]),
                    "album": .object([
                        "type": .string("string"),
                        "description": .string("Album name")
                    ])
                ]),
                "required": .array([.string("artist"), .string("track")])
            ])
        )
        
        return [
            authenticateTool,
            searchArtistTool,
            getArtistInfoTool,
            getSimilarArtistsTool,
            searchAlbumTool,
            getAlbumInfoTool,
            searchTrackTool,
            getUserRecentTracksTool,
            getUserTopArtistsTool,
            scrobbleTrackTool
        ]
    }
    
    static func executeToolCall(toolName: String, arguments: [String: Any]?, lastFM: LastFMService) async throws -> String? {
        // Handle nil arguments by using an empty dictionary
        let params = arguments ?? [:]
        
        // Debug the received arguments for each tool call
        logger.info("Executing tool \(toolName) with arguments: \(params)")
        
        switch toolName {
        case "authenticate_user":
            guard let usernameValue = params["username"],
                  let passwordValue = params["password"] else {
                throw MCPError.invalidParams("Missing required parameters: username and password")
            }
            
            let username = "\(usernameValue)"
            let password = "\(passwordValue)"
            
            do {
                let success = try await lastFM.authenticate(username: username, password: password)
                let result = ["success": success]
                return try JSONEncoder().encode(result).prettyPrintedJSON()
            } catch {
                let result = ["error": error.localizedDescription]
                return try JSONEncoder().encode(result).prettyPrintedJSON()
            }
            
        case "search_artist":
            guard let queryValue = params["query"] else {
                throw MCPError.invalidParams("Missing required parameter: query")
            }
            
            let query = "\(queryValue)"
            let limitValue = params["limit"]
            let limit: Int = limitValue != nil ? (Int("\(limitValue!)") ?? 10) : 10
            
            do {
                let artists = try await lastFM.searchArtist(query: query, limit: limit)
                let result = formatArtistResults(artists)
                return try JSONSerialization.data(withJSONObject: result).prettyPrintedJSON()
            } catch {
                let result = ["error": error.localizedDescription]
                return try JSONEncoder().encode(result).prettyPrintedJSON()
            }
            
        case "get_artist_info":
            guard let nameValue = params["name"] else {
                throw MCPError.invalidParams("Missing required parameter: name")
            }
            
            let name = "\(nameValue)"
            
            do {
                let artist = try await lastFM.getArtistInfo(name: name)
                let result = formatArtistInfo(artist)
                return try JSONSerialization.data(withJSONObject: result).prettyPrintedJSON()
            } catch {
                let result = ["error": error.localizedDescription]
                return try JSONEncoder().encode(result).prettyPrintedJSON()
            }
            
        case "get_similar_artists":
            guard let nameValue = params["name"] else {
                throw MCPError.invalidParams("Missing required parameter: name")
            }
            
            let name = "\(nameValue)"
            let limitValue = params["limit"]
            let limit: Int = limitValue != nil ? (Int("\(limitValue!)") ?? 10) : 10
            
            do {
                let artists = try await lastFM.getSimilarArtists(name: name, limit: limit)
                let result = formatSimilarArtists(artists)
                return try JSONSerialization.data(withJSONObject: result).prettyPrintedJSON()
            } catch {
                let result = ["error": error.localizedDescription]
                return try JSONEncoder().encode(result).prettyPrintedJSON()
            }
            
        case "search_album":
            guard let queryValue = params["query"] else {
                throw MCPError.invalidParams("Missing required parameter: query")
            }
            
            let query = "\(queryValue)"
            let limitValue = params["limit"]
            let limit: Int = limitValue != nil ? (Int("\(limitValue!)") ?? 10) : 10
            
            do {
                let albums = try await lastFM.searchAlbum(query: query, limit: limit)
                let result = formatAlbumResults(albums)
                return try JSONSerialization.data(withJSONObject: result).prettyPrintedJSON()
            } catch {
                let result = ["error": error.localizedDescription]
                return try JSONEncoder().encode(result).prettyPrintedJSON()
            }
            
        case "get_album_info":
            guard let albumValue = params["album"],
                  let artistValue = params["artist"] else {
                throw MCPError.invalidParams("Missing required parameters: album and artist")
            }
            
            let album = "\(albumValue)"
            let artist = "\(artistValue)"
            
            do {
                let albumInfo = try await lastFM.getAlbumInfo(album: album, artist: artist)
                let result = formatAlbumInfo(albumInfo)
                return try JSONSerialization.data(withJSONObject: result).prettyPrintedJSON()
            } catch {
                let result = ["error": error.localizedDescription]
                return try JSONEncoder().encode(result).prettyPrintedJSON()
            }
            
        case "search_track":
            guard let queryValue = params["query"] else {
                throw MCPError.invalidParams("Missing required parameter: query")
            }
            
            let query = "\(queryValue)"
            let artistValue = params["artist"]
            let artist = artistValue != nil ? "\(artistValue!)" : nil
            let limitValue = params["limit"]
            let limit: Int = limitValue != nil ? (Int("\(limitValue!)") ?? 10) : 10
            
            do {
                let tracks = try await lastFM.searchTrack(query: query, artist: artist, limit: limit)
                let result = formatTrackResults(tracks)
                return try JSONSerialization.data(withJSONObject: result).prettyPrintedJSON()
            } catch {
                let result = ["error": error.localizedDescription]
                return try JSONEncoder().encode(result).prettyPrintedJSON()
            }
            
        case "get_user_recent_tracks":
            guard let usernameValue = params["username"] else {
                logger.error("Username parameter is missing completely")
                throw MCPError.invalidParams("Missing required parameter: username")
            }
            
            let username = "\(usernameValue)"
            let limitValue = params["limit"]
            let limit: Int = limitValue != nil ? (Int("\(limitValue!)") ?? 10) : 10
            
            do {
                let recentTracks = try await lastFM.getUserRecentTracks(user: username, limit: limit)
                let result = formatRecentTracks(recentTracks)
                return try JSONSerialization.data(withJSONObject: result).prettyPrintedJSON()
            } catch {
                logger.error("Error getting recent tracks: \(error)")
                let result = ["error": error.localizedDescription]
                return try JSONEncoder().encode(result).prettyPrintedJSON()
            }
            
        case "get_user_top_artists":
            guard let usernameValue = params["username"] else {
                throw MCPError.invalidParams("Missing required parameter: username")
            }
            
            let username = "\(usernameValue)"
            let limitValue = params["limit"]
            let limit: Int = limitValue != nil ? (Int("\(limitValue!)") ?? 10) : 10
            
            do {
                let topArtists = try await lastFM.getUserTopArtists(user: username, limit: limit)
                let result = formatUserTopArtists(topArtists)
                return try JSONSerialization.data(withJSONObject: result).prettyPrintedJSON()
            } catch {
                let result = ["error": error.localizedDescription]
                return try JSONEncoder().encode(result).prettyPrintedJSON()
            }
            
        case "scrobble_track":
            guard let artistValue = params["artist"],
                  let trackValue = params["track"] else {
                throw MCPError.invalidParams("Missing required parameters: artist and track")
            }
            
            let artist = "\(artistValue)"
            let track = "\(trackValue)"
            let albumValue = params["album"]
            let album = albumValue != nil ? "\(albumValue!)" : nil
            
            do {
                let success = try await lastFM.scrobbleTrack(artist: artist, track: track, album: album)
                let result = ["success": success]
                return try JSONEncoder().encode(result).prettyPrintedJSON()
            } catch {
                let result = ["error": error.localizedDescription]
                return try JSONEncoder().encode(result).prettyPrintedJSON()
            }
            
        default:
            logger.error("Unknown tool: \(toolName)")
            return nil
        }
    }
}

// Helper formatters for the results
func formatArtistResults(_ artists: [SBKArtist]) -> [String: Any] {
    let formattedArtists = artists.map { artist -> [String: Any] in
        var artistDict: [String: Any] = [
            "name": artist.name,
            "url": artist.url?.absoluteString ?? ""
        ]
        
        if let listeners = artist.listeners {
            artistDict["listeners"] = listeners
        }
        
        if let imageURL = artist.image?.largestSize?.absoluteString {
            artistDict["image"] = imageURL
        }
        
        return artistDict
    }
    
    return ["artists": formattedArtists]
}

func formatArtistInfo(_ artist: SBKArtist) -> [String: Any] {
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

func formatSimilarArtists(_ artists: [SBKSimilarArtist]) -> [String: Any] {
    let formattedArtists = artists.map { similarArtist -> [String: Any] in
        var artistDict: [String: Any] = [
            "name": similarArtist.artist.name,
            "url": similarArtist.artist.url?.absoluteString ?? ""
        ]
        
        if let match = similarArtist.match {
            artistDict["match"] = match
        }
        
        if let imageURL = similarArtist.artist.image?.largestSize?.absoluteString {
            artistDict["image"] = imageURL
        }
        
        return artistDict
    }
    
    return ["similar_artists": formattedArtists]
}

func formatAlbumResults(_ albums: [SBKAlbum]) -> [String: Any] {
    let formattedAlbums = albums.map { album -> [String: Any] in
        var albumDict: [String: Any] = [
            "name": album.name,
            "artist": album.artist,
            "url": album.url?.absoluteString ?? ""
        ]
        
        if let imageURL = album.artwork?.largestSize?.absoluteString {
            albumDict["image"] = imageURL
        }
        
        return albumDict
    }
    
    return ["albums": formattedAlbums]
}

func formatAlbumInfo(_ album: SBKAlbum) -> [String: Any] {
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
    
    if !album.tracklist.isEmpty {
        result["tracks"] = album.tracklist.map { track -> [String: Any] in
            var trackDict: [String: Any] = [
                "name": track.name,
                "artist": track.artist.name
            ]
            
            if let duration = track.duration {
                trackDict["duration"] = duration
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

func formatTrackResults(_ tracks: [SBKTrack]) -> [String: Any] {
    let formattedTracks = tracks.map { track -> [String: Any] in
        var trackDict: [String: Any] = [
            "name": track.name,
            "artist": track.artist.name,
            "url": track.url?.absoluteString ?? ""
        ]
        
        if let listeners = track.listeners {
            trackDict["listeners"] = listeners
        }
        
        if let imageURL = track.artwork?.largestSize?.absoluteString {
            trackDict["image"] = imageURL
        }
        
        return trackDict
    }
    
    return ["tracks": formattedTracks]
}

func formatRecentTracks(_ recentTracks: SBKSearchResult<SBKScrobbledTrack>) -> [String: Any] {
    let formattedTracks = recentTracks.results.map { scrobbledTrack -> [String: Any] in
        let track = scrobbledTrack.track
        
        var trackDict: [String: Any] = [
            "name": track.name,
            "artist": track.artist.name,
            "url": track.url?.absoluteString ?? ""
        ]
        
        if let date = scrobbledTrack.date {
            trackDict["date"] = date.timeIntervalSince1970
        }
        
        if let imageURL = track.artwork?.largestSize?.absoluteString {
            trackDict["image"] = imageURL
        }
        
        return trackDict
    }
    
    return [
        "recent_tracks": formattedTracks,
        "metadata": [
            "page": recentTracks.page,
            "per_page": recentTracks.perPage,
            "total_pages": recentTracks.totalPages,
            "total": recentTracks.total
        ]
    ]
}

func formatUserTopArtists(_ topArtists: SBKSearchResult<SBKArtist>) -> [String: Any] {
    let formattedArtists = topArtists.results.map { artist -> [String: Any] in
        var artistDict: [String: Any] = [
            "name": artist.name,
            "url": artist.url?.absoluteString ?? ""
        ]
        
        if let playcount = artist.playcount {
            artistDict["playcount"] = playcount
        }
        
        if let imageURL = artist.image?.largestSize?.absoluteString {
            artistDict["image"] = imageURL
        }
        
        return artistDict
    }
    
    return [
        "top_artists": formattedArtists,
        "metadata": [
            "page": topArtists.page,
            "per_page": topArtists.perPage,
            "total_pages": topArtists.totalPages,
            "total": topArtists.total
        ]
    ]
}

// Helper extension for pretty-printing JSON
extension Data {
    func prettyPrintedJSON() throws -> String {
        let jsonObject = try JSONSerialization.jsonObject(with: self)
        let prettyData = try JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted])
        guard let prettyString = String(data: prettyData, encoding: .utf8) else {
            throw NSError(domain: "JSON", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert JSON data to string"])
        }
        return prettyString
    }
}
