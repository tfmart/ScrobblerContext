//
//  AuthTools.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 24/05/25.
//

import Foundation
import MCP
@preconcurrency import ScrobbleKit
import Logging

/// Authentication-related tools for the Last.fm MCP Server
struct AuthTools {
    private let lastFMService: LastFMService
    private let logger = Logger(label: "com.lastfm.mcp-server.auth")
    
    init(lastFMService: LastFMService) {
        self.lastFMService = lastFMService
    }
    
    // MARK: - Tool Definitions
    
    static func createTools() -> [Tool] {
        return [
            createAuthenticateTool(),
            createSetSessionKeyTool(),
            createCheckAuthStatusTool()
        ]
    }
    
    private static func createAuthenticateTool() -> Tool {
        return Tool(
            name: ToolName.authenticateUser.rawValue,
            description: ToolName.authenticateUser.description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "username": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm username (not email)")
                    ]),
                    "password": .object([
                        "type": .string("string"),
                        "description": .string("Last.fm password")
                    ])
                ]),
                "required": .array([.string("username"), .string("password")])
            ])
        )
    }
    
    private static func createSetSessionKeyTool() -> Tool {
        return Tool(
            name: ToolName.setSessionKey.rawValue,
            description: ToolName.setSessionKey.description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "session_key": .object([
                        "type": .string("string"),
                        "description": .string("Valid Last.fm session key")
                    ])
                ]),
                "required": .array([.string("session_key")])
            ])
        )
    }
    
    private static func createCheckAuthStatusTool() -> Tool {
        return Tool(
            name: ToolName.checkAuthStatus.rawValue,
            description: ToolName.checkAuthStatus.description,
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([:]),
                "required": .array([])
            ])
        )
    }
    
    // MARK: - Tool Execution
    
    func execute(toolName: ToolName, arguments: [String: (any Sendable)]) async throws -> ToolResult {
        logger.info("Executing auth tool: \(toolName.rawValue)")
        
        switch toolName {
        case .authenticateUser:
            return try await executeAuthenticate(arguments: arguments)
        case .setSessionKey:
            return try await executeSetSessionKey(arguments: arguments)
        case .checkAuthStatus:
            return try await executeCheckAuthStatus(arguments: arguments)
        default:
            throw ToolError.lastFMError("Invalid authentication tool: \(toolName.rawValue)")
        }
    }
    
    // MARK: - Individual Tool Implementations
    
    private func executeAuthenticate(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let input = try parseAuthenticateInput(arguments)
        
        do {
            let sessionInfo = try await lastFMService.authenticate(
                username: input.username,
                password: input.password
            )
            
            logger.info("Successfully authenticated user: \(input.username)")
            
            let result = ResponseFormatters.formatAuthenticationResult(
                true,
                username: sessionInfo.name
            )
            
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Authentication failed for user \(input.username): \(error)")
            return ToolResult.failure(error: "Authentication failed: \(error.localizedDescription)")
        }
    }
    
    private func executeSetSessionKey(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        guard let sessionKeyValue = arguments["session_key"] else {
            throw ToolError.missingParameter("session_key")
        }
        
        let sessionKey = "\(sessionKeyValue)"
        
        do {
            try await lastFMService.setSessionKey(sessionKey)
            logger.info("Session key set successfully")
            
            let result = ResponseFormatters.formatAuthenticationResult(true)
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to set session key: \(error)")
            return ToolResult.failure(error: "Failed to set session key: \(error.localizedDescription)")
        }
    }
    
    private func executeCheckAuthStatus(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let isAuthenticated = await lastFMService.isAuthenticated()
        
        let result: [String: Any] = [
            "authenticated": isAuthenticated,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        return ToolResult.success(data: result)
    }
    
    // MARK: - Input Parsing Helpers
    
    private func parseAuthenticateInput(_ arguments: [String: (any Sendable)]) throws -> AuthenticateInput {
        guard let usernameValue = arguments["username"] else {
            throw ToolError.missingParameter("username")
        }
        
        guard let passwordValue = arguments["password"] else {
            throw ToolError.missingParameter("password")
        }
        
        return AuthenticateInput(
            username: "\(usernameValue)",
            password: "\(passwordValue)"
        )
    }
}

extension LastFMService {
    func setSessionKey(_ key: String) async throws {
        manager.setSessionKey(key)
        logger.info("Session key set")
        
        // Optionally validate the session key by making a test call
        // This is useful to verify the key is valid
        do {
            _ = try await manager.getInfo(forUser: nil)
            logger.info("Session key validated successfully")
        } catch {
            logger.warning("Session key validation failed: \(error)")
            // Don't throw here - the key might still be valid for other operations
        }
    }
    
    func isAuthenticated() async -> Bool {
        return manager.sessionKey != nil
    }
}
