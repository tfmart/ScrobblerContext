# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Building and Running
- Build: `swift build`
- Run: `swift run ScrobblerContext`
- Test: `swift test`
- Clean: `swift package clean`

### Environment Setup
Set these environment variables before running:
```bash
export LASTFM_API_KEY="your_api_key_here"
export LASTFM_SECRET_KEY="your_secret_key_here"
```

### Deployment

**For Smithery/MCP Clients:**
- Mark as **Local** deployment (not Remote) - this runs the Swift server locally while Smithery handles MCP integration
- Requires Last.fm API credentials in environment variables
- Remote deployment fails due to Swift runtime requirements on hosting platform

## Architecture Overview

This is a **Model Context Protocol (MCP) server** that provides Last.fm API access to AI assistants. The architecture follows a clean separation between protocol handling, service layer, and domain models.

### Core Components

**MCPServer** (`Sources/ScrobblerContext/Server/MCPServer.swift:13`)
- Main MCP protocol server using Swift MCP SDK
- Handles stdio transport and tool registration
- Entry point is `ScrobblerContextMain.swift:13`

**LastFMService** (`Sources/ScrobblerContext/Services/LastFMService.swift:17`)
- Core service wrapping ScrobbleKit for Last.fm API calls
- Manages OAuth authentication flow with session persistence
- Handles all API operations: search, scrobble, user data, etc.

**Tool System Architecture**
- **ToolRegistry** (`Sources/ScrobblerContext/Tools/ToolRegistry.swift:13`): Central registry managing all tool categories
- **ToolExecutor** (`Sources/ScrobblerContext/Tools/ToolExecutor.swift`): Executes tools and validates arguments
- **Tool Categories** (`Sources/ScrobblerContext/Tools/Categories/`): Organized by domain (Auth, Artist, Album, Track, User, Scrobble)

### Authentication Flow
The server implements OAuth 2.0 with Last.fm:
1. Browser-based OAuth via `authenticate_browser` tool
2. Session key exchange and persistence
3. Automatic session restoration on startup
4. All authenticated operations validate session before execution

### Dependencies
- **ScrobbleKit**: Last.fm API Swift SDK (custom "sendable" branch)
- **MCP Swift SDK**: Model Context Protocol implementation
- **Swifter**: HTTP server for OAuth callback handling

### Session Management
- `SessionManager`: Thread-safe session state management
- `SessionPersistenceManager`: Saves/restores sessions across restarts
- Sessions stored in user's home directory for persistence

### Tool Organization
Tools are categorized into 6 domains with ~60 total tools:
- **Authentication**: OAuth flow, session management
- **Artist**: Search, info, similar artists, tags, top albums/tracks
- **Album**: Search, info, tags, track listings  
- **Track**: Search, info, similar tracks, corrections, tags
- **User**: Profile, recent tracks, top items by time period, friends
- **Scrobble**: Submit plays, update now playing, love/unlove tracks

### Response Formatting
All tool responses use structured data via `ResponseFormatters.swift:1` to ensure consistent JSON output for MCP clients.