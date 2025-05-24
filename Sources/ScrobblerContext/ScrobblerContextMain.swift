//
//  main.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 17/05/25.
//

import Foundation
import Logging

/// Main entry point for the Last.fm MCP Server
@main
struct ScrobblerContextMain {
    static var logger: Logger {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardError(label: label)
            handler.logLevel = .info
            return handler
        }

        return Logger(label: "com.lastfm.mcp-server.main")
    }
    
    static func main() async {
        logger.info("🎵 Starting Last.fm MCP Server...")
        
        do {
            // Initialize and start the server
            let mcpServer = try MCPServer()
            
            // Start the server
            try await mcpServer.start()
            
            // Wait for completion
            await mcpServer.waitForCompletion()
            
        } catch let configError as ConfigurationError {
            logger.error("❌ Configuration error: \(configError.localizedDescription)")
            logger.info("💡 Make sure to set LASTFM_API_KEY and LASTFM_SECRET_KEY environment variables")
            exit(1)
            
        } catch {
            logger.error("❌ Failed to start server: \(error)")
            exit(1)
        }
        
        logger.info("🛑 Server shutdown complete")
    }
}
