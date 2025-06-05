# ScrobblerContext - Last.fm MCP Server

[![npm version](https://badge.fury.io/js/scrobblercontext-mcp.svg)](https://badge.fury.io/js/scrobblercontext-mcp)
[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![MCP](https://img.shields.io/badge/MCP-Compatible-blue.svg)](https://modelcontextprotocol.io)

A Model Context Protocol (MCP) server that provides access to Last.fm's music database. Built in Swift, it enables AI assistants to search for music, manage user libraries, and scrobble tracks.

## Table of Contents

- [Features](#features)
- [Quick Start](#quick-start)
- [Setup with MCP Clients](#setup-with-mcp-clients)
- [Usage Examples](#usage-examples)
- [Manual Installation](#manual-installation)
- [Available Tools](#available-tools)
- [Contributing](#contributing)
- [Documentation](#documentation)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [Acknowledgments](#acknowledgments)

## Features

- **Authentication**: Secure browser OAuth flow with session persistence
- **Artist Operations**: Search artists, get detailed information, find similar artists
- **Album Operations**: Search albums, get track listings and metadata
- **Track Operations**: Search tracks, get details and recommendations
- **User Data**: Access listening history, statistics, and social features
- **Scrobbling**: Submit track plays, update now playing status, love/unlove tracks

## Quick Start

### Install via npm (Recommended)

```bash
# Install globally
npm install -g scrobblercontext-mcp

# Set up your Last.fm API credentials
export LASTFM_API_KEY="your_api_key_here"
export LASTFM_SECRET_KEY="your_secret_key_here"

# Run the server
scrobblercontext-mcp
```

### Get Last.fm API Credentials

1. Visit [Last.fm API Account Creation](https://www.last.fm/api/account/create)
2. Fill in the application details:
   - **Application Name**: Your app name (e.g., "My MCP Server")
   - **Application Description**: Brief description
   - **Application Homepage URL**: Your website (can be GitHub repo)
   - **Callback URL**: `http://localhost:8080/callback` (for OAuth)
3. Save your **API Key** and **Shared Secret**

## Setup with MCP Clients

### Claude Desktop

Add to your `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "lastfm": {
      "command": "scrobblercontext-mcp",
      "env": {
        "LASTFM_API_KEY": "your_api_key_here",
        "LASTFM_SECRET_KEY": "your_secret_key_here"
      }
    }
  }
}
```

**Configuration file locations:**
- **macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Windows**: `%APPDATA%/Claude/claude_desktop_config.json`

### Cursor

Add to your MCP settings:

```json
{
  "mcpServers": {
    "lastfm": {
      "command": "scrobblercontext-mcp",
      "env": {
        "LASTFM_API_KEY": "your_api_key_here", 
        "LASTFM_SECRET_KEY": "your_secret_key_here"
      }
    }
  }
}
```

### Other MCP Clients

The server communicates over **stdio** following the Model Context Protocol standard. Configure your client to:
1. Execute `scrobblercontext-mcp` as the server command
2. Set the required environment variables
3. Use stdio transport

## Usage Examples

Authenticate with Last.fm:
```
User: "Authenticate with Last.fm"
Assistant: [Uses authenticate_browser tool to start OAuth flow]
```

Search for music:
```
User: "Find artists similar to Radiohead" 
Assistant: [Uses get_similar_artists tool to find recommendations]
```

Scrobble tracks:
```
User: "Scrobble 'Bohemian Rhapsody' by Queen"
Assistant: [Uses scrobble_track tool to submit to your profile]
```

## Manual Installation

**Prerequisites:**
- Swift 6.0+ ([Download](https://swift.org/download/))
- macOS 13.0+ or Linux with Swift support
- Last.fm API credentials

**Build from source:**

```bash
git clone https://github.com/tfmart/ScrobblerContext
cd ScrobblerContext
swift build
export LASTFM_API_KEY="your_api_key_here"
export LASTFM_SECRET_KEY="your_secret_key_here"
swift run ScrobblerContext
```

## Available Tools

<details>
<summary><strong>Authentication Tools (5)</strong></summary>

- `authenticate_browser` - Start OAuth flow in browser
- `set_session_key` - Set existing session key
- `check_auth_status` - Check authentication status  
- `restore_session` - Restore saved session
- `logout` - Clear authentication

</details>

<details>
<summary><strong>Artist Tools (9)</strong></summary>

- `search_artist` - Search for artists
- `get_artist_info` - Get artist details & biography
- `get_similar_artists` - Find similar artists
- `get_artist_correction` - Get corrected artist name
- `get_artist_tags` - Get artist tags
- `get_artist_top_albums` - Get artist's top albums
- `get_artist_top_tracks` - Get artist's top tracks
- `add_artist_tags` - Add personal tags (requires auth)
- `remove_artist_tag` - Remove personal tag (requires auth)

</details>

<details>
<summary><strong>Album Tools (6)</strong></summary>

- `search_album` - Search for albums
- `get_album_info` - Get album details & tracklist
- `get_album_tags` - Get album tags
- `get_album_top_tags` - Get popular album tags
- `add_album_tags` - Add personal tags (requires auth)
- `remove_album_tag` - Remove personal tag (requires auth)

</details>

<details>
<summary><strong>Track Tools (8)</strong></summary>

- `search_track` - Search for tracks
- `get_track_info` - Get track details
- `get_similar_tracks` - Find similar tracks
- `get_track_correction` - Get corrected track info
- `get_track_tags` - Get track tags
- `get_track_top_tags` - Get popular track tags
- `add_track_tags` - Add personal tags (requires auth)
- `remove_track_tag` - Remove personal tag (requires auth)

</details>

<details>
<summary><strong>User Tools (9)</strong></summary>

- `get_user_info` - Get user profile & stats
- `get_user_recent_tracks` - Get recent listening history
- `get_user_top_artists` - Get top artists by period
- `get_user_top_tracks` - Get top tracks by period
- `get_user_top_albums` - Get top albums by period
- `get_user_top_tags` - Get most used tags
- `get_user_friends` - Get friends list
- `get_user_loved_tracks` - Get loved tracks
- `get_user_personal_tags_for_artists` - Get tagged artists

</details>

<details>
<summary><strong>Scrobble Tools (5)</strong></summary>

- `scrobble_track` - Submit single track play
- `scrobble_multiple_tracks` - Submit multiple plays
- `update_now_playing` - Update current track status
- `love_track` - Mark track as loved
- `unlove_track` - Remove from loved tracks

</details>

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Documentation

- [API Documentation](https://tfmart.github.io/ScrobblerContext/documentation/scrobblercontext/) - Auto-generated from code
- [Contributing Guide](CONTRIBUTING.md) - Development setup and guidelines
- [Model Context Protocol](https://modelcontextprotocol.io/) - MCP specification
- [Last.fm API](https://www.last.fm/api) - Last.fm API documentation

## Troubleshooting

**Swift not found**: Install Swift from [swift.org](https://swift.org/download/)

**Invalid session key**: Re-run authentication with `authenticate_browser`

**API key errors**: Verify your `LASTFM_API_KEY` and `LASTFM_SECRET_KEY` are correct

**Server disconnects**: Check environment variables are set in MCP client config

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Last.fm](https://www.last.fm/) for the music data API
- [ScrobbleKit](https://github.com/tfmart/ScrobbleKit) for the Swift Last.fm SDK
- [Model Context Protocol](https://modelcontextprotocol.io/) for the communication standard