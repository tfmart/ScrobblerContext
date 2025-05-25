# ScrobblerContext - Last.fm MCP Server

A Model Context Protocol (MCP) server that provides access to Last.fm's API, built in Swift. Enables AI assistants to search for data suchs as songs, artists and albums on Last.fm, manage user libraries, and scrobble tracks.

## Features

### Authentication
- `authenticate_browser` - Authenticate using secure browser OAuth flow
- `set_session_key` - Set an existing Last.fm session key  
- `check_auth_status` - Check current authentication status
- `restore_session` - Restore authentication from saved session
- `logout` - Clear authentication and logout

### Artist Operations
- `search_artist` - Search for artists by name
- `get_artist_info` - Get detailed artist information and biography
- `get_similar_artists` - Find artists similar to specified artist
- `get_artist_correction` - Get corrected artist name if available
- `get_artist_tags` - Get tags applied to an artist
- `get_artist_top_albums` - Get artist's most popular albums
- `get_artist_top_tracks` - Get artist's most popular tracks
- `add_artist_tags` - Add personal tags to an artist (requires auth)
- `remove_artist_tag` - Remove personal tag from artist (requires auth)

### Album Operations
- `search_album` - Search for albums by name
- `get_album_info` - Get detailed album information and tracklist
- `get_album_tags` - Get tags applied to an album
- `get_album_top_tags` - Get most popular tags for an album
- `add_album_tags` - Add personal tags to an album (requires auth)
- `remove_album_tag` - Remove personal tag from album (requires auth)

### Track Operations
- `search_track` - Search for tracks by name and optional artist
- `get_track_info` - Get detailed track information
- `get_similar_tracks` - Find tracks similar to specified track
- `get_track_correction` - Get corrected track and artist names
- `get_track_tags` - Get tags applied to a track
- `get_track_top_tags` - Get most popular tags for a track
- `add_track_tags` - Add personal tags to a track (requires auth)
- `remove_track_tag` - Remove personal tag from track (requires auth)

### User Data
- `get_user_info` - Get user profile information and statistics
- `get_user_recent_tracks` - Get user's recently played tracks
- `get_user_top_artists` - Get user's top artists by time period
- `get_user_top_tracks` - Get user's top tracks by time period
- `get_user_top_albums` - Get user's top albums by time period
- `get_user_top_tags` - Get user's most used tags
- `get_user_friends` - Get user's friends list
- `get_user_loved_tracks` - Get user's loved tracks
- `get_user_personal_tags_for_artists` - Get artists tagged with specific personal tag

### Scrobbling & Library Management
- `scrobble_track` - Submit a track play to user's library (requires auth)
- `scrobble_multiple_tracks` - Submit multiple track plays at once (requires auth)
- `update_now_playing` - Update currently playing track status (requires auth)
- `love_track` - Mark a track as loved (requires auth)
- `unlove_track` - Remove track from loved tracks (requires auth)

## Installation

### Prerequisites
- Swift 6.0 or later
- macOS 13.0 or later
- Last.fm API credentials ([Get them here](https://www.last.fm/api/account/create))

### Setup

1. **Clone and build**:
   ```bash
   git clone https://github.com/tfmart/ScrobblerContext
   cd ScrobblerContext
   swift build
   ```

2. **Set environment variables**:
   ```bash
   export LASTFM_API_KEY="your_api_key_here"
   export LASTFM_SECRET_KEY="your_secret_key_here"
   ```

3. **Run the server**:
   ```bash
   swift run ScrobblerContext
   ```

The server communicates over stdio following the MCP protocol.

## Using with MCP Clients

### Claude Desktop

Add to your Claude Desktop MCP configuration:

```json
{
  "mcpServers": {
    "lastfm": {
      "command": "path/to/ScrobblerContext",
      "env": {
        "LASTFM_API_KEY": "your_api_key_here",
        "LASTFM_SECRET_KEY": "your_secret_key_here"
      }
    }
  }
}
```

### Cursor

```json
{
  "mcpServers": {
    "swift-version-server": {
      "type": "stdio",
      "command": "path/to/ScrobblerContext"
    }
  }
}
```

### Other MCP Clients

Configure your MCP client to:
1. Create the `ScrobblerContext` executable
2. Set the required environment variables
3. Communicate over stdio

### Authentication

Before using authenticated features, run the authentication flow:

1. Use `authenticate_browser` tool to start OAuth flow
2. Complete authentication in your browser
3. Session will be saved automatically for future use

## Acknowledgments

- [Last.fm](https://www.last.fm/) for providing the music data API
- [ScrobbleKit](https://github.com/tfmart/ScrobbleKit) for the Swift Last.fm SDK
- [Model Context Protocol](https://modelcontextprotocol.io/) for the communication standard
