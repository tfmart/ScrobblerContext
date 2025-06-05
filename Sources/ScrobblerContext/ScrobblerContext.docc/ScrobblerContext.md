# ``ScrobblerContext``

A powerful Last.fm MCP Server that brings music discovery and scrobbling to AI assistants.

## Overview

ScrobblerContext is a Model Context Protocol (MCP) server built in Swift that provides comprehensive access to Last.fm's music database. It enables AI assistants to perform music discovery, manage user libraries, and handle scrobbling operations through natural conversation.

### Key Features

- **🔐 Secure Authentication**: OAuth 2.0 flow with session persistence
- **🎵 Music Discovery**: Search artists, albums, and tracks with detailed metadata
- **📊 Scrobbling**: Real-time track submission and library management
- **👤 User Data**: Access listening history, statistics, and social features
- **🏷️ Tagging System**: Personal tag management for music organization

## Getting Started

### Installation

Install via npm for the easiest setup:

```bash
npm install -g scrobblercontext-mcp
```

### Configuration

Set up your Last.fm API credentials:

```bash
export LASTFM_API_KEY="your_api_key_here"
export LASTFM_SECRET_KEY="your_secret_key_here"
```

### Running the Server

```bash
scrobblercontext-mcp
```

## Architecture

The server follows a clean architecture pattern with clear separation of concerns:

### Core Components

- ``MCPServer``: Main protocol server handling MCP communication
- ``LastFMService``: Core service managing Last.fm API interactions
- ``ToolRegistry``: Central registry for all available tools
- ``SessionManager``: Thread-safe session state management

### Tool Categories

The server provides 60+ tools organized into logical categories:

- **Authentication**: OAuth flow and session management
- **Artist Operations**: Search, information, and discovery
- **Album Operations**: Metadata, tracks, and artwork
- **Track Operations**: Details, recommendations, and corrections
- **User Data**: Statistics, history, and social features
- **Scrobbling**: Play submission and library management

## Topics

### Core Components

- ``MCPServer``
- ``LastFMService``
- ``ToolRegistry``
- ``SessionManager``

### Tool Categories

- ``AuthTools``
- ``ArtistTools``
- ``AlbumTools``
- ``TrackTools``
- ``UserTools``
- ``ScrobbleTools``

### Models and Utilities

- ``ToolExecutor``
- ``Configuration``
- ``SessionPersistenceManager``