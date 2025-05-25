//
//  AuthTools.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation
import MCP
import Logging
#if canImport(AppKit)
import AppKit
#endif

/// Authentication-related tools for the Last.fm MCP Server
struct AuthTools {
    private let lastFMService: LastFMService
    private let logger = Logger(label: "com.lastfm.mcp-server.auth")
    
    // OAuth state management using actor for thread safety
    private static let oauthStateManager = OAuthStateManager()
    
    init(lastFMService: LastFMService) {
        self.lastFMService = lastFMService
    }
    
    // MARK: - Tool Creation
    
    static func createTools() -> [Tool] {
        return [
            createBrowserAuthTool(),
            createSetSessionKeyTool(),
            createCheckAuthStatusTool(),
            createRestoreSessionTool(),
            createLogoutTool()
        ]
    }
    
    private static func createBrowserAuthTool() -> Tool {
        return Tool(
            name: "authenticate_browser",
            description: "🔐 Authenticate with Last.fm using secure browser OAuth flow (recommended)",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "port": .object([
                        "type": .string("integer"),
                        "description": .string("Local server port for OAuth callback (default: 4567)"),
                        "default": .int(4567),
                        "minimum": .int(1024),
                        "maximum": .int(65535)
                    ]),
                    "auto_open": .object([
                        "type": .string("boolean"),
                        "description": .string("Automatically open browser (default: true)"),
                        "default": .bool(true)
                    ])
                ]),
                "required": .array([])
            ])
        )
    }
    
    private static func createSetSessionKeyTool() -> Tool {
        return Tool(
            name: "set_session_key",
            description: "Set an existing Last.fm session key for authentication",
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
            name: "check_auth_status",
            description: "Check current authentication status with Last.fm",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([:]),
                "required": .array([])
            ])
        )
    }
    
    private static func createRestoreSessionTool() -> Tool {
        return Tool(
            name: "restore_session",
            description: "Restore authentication from saved session data",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([:]),
                "required": .array([])
            ])
        )
    }
    
    private static func createLogoutTool() -> Tool {
        return Tool(
            name: "logout",
            description: "Clear authentication session and logout from Last.fm",
            inputSchema: .object([
                "type": .string("object"),
                "properties": .object([:]),
                "required": .array([])
            ])
        )
    }
    
    // MARK: - Tool Execution
    
    func execute(toolName: ToolName, arguments: [String: (any Sendable)]) async throws -> ToolResult {
        logger.info("Executing authentication tool: \(toolName)")
        
        switch toolName {
        case .authenticateBrowser:
            return try await executeBrowserAuth(arguments: arguments)
        case .setSessionKey:
            return try await executeSetSessionKey(arguments: arguments)
        case .checkAuthStatus:
            return try await executeCheckAuthStatus(arguments: arguments)
        case .restoreSession:
            return try await executeRestoreSession(arguments: arguments)
        case .logout:
            return try await executeLogout(arguments: arguments)
        default:
            throw ToolError.lastFMError("Unknown authentication tool: \(toolName)")
        }
    }
    
    // MARK: - Browser OAuth Implementation
    
    private func executeBrowserAuth(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let port = try arguments.getValidatedInt(for: "port", min: 1024, max: 65535, default: 4567) ?? 4567
        let autoOpen = arguments.getBool(for: "auto_open") ?? true
        
        do {
            // Generate random state for CSRF protection
            let state = UUID().uuidString
            logger.info("🔑 Generated OAuth state: '\(state)'")
            
            await Self.oauthStateManager.setState(state)
            
            // Verify state was stored correctly
            let storedState = await Self.oauthStateManager.getState()
            logger.info("📋 Verified stored state: '\(storedState ?? "nil")'")
            
            // Start local OAuth callback server
            let callbackServer = OAuthCallbackServer(port: port, lastFMService: lastFMService)
            await Self.oauthStateManager.setCallbackServer(callbackServer)
            
            await callbackServer.setExpectedState(state)
            
            // Verify state was set in callback server
            logger.info("🔧 State set in callback server")
            
            try await callbackServer.start()
            logger.info("🚀 Started OAuth callback server on http://localhost:\(port)")
            
            // Generate Last.fm authorization URL
            let authURL = generateAuthURL(
                callbackURL: "http://localhost:\(port)/callback",
                state: state
            )
            
            logger.info("🔗 Generated OAuth URL: \(authURL)")
            
            // Prepare response with instructions
            var result: [String: Any] = [
                "auth_url": authURL,
                "callback_port": port,
                "callback_url": "http://localhost:\(port)/callback",
                "state": state,
                "instructions": [
                    "1. Click the auth_url or copy it to your browser",
                    "2. Log in to Last.fm and authorize the application",
                    "3. You'll be redirected back automatically",
                    "4. Keep this process running until authentication completes"
                ],
                "status": "awaiting_user_authorization",
                "timeout_seconds": 300
            ]
            
            if autoOpen {
                openURL(authURL)
                result["browser_opened"] = true
                result["message"] = "Browser opened automatically. Please complete the authorization in your browser."
            } else {
                result["message"] = "Please open the auth_url in your browser to complete authorization."
            }
            
            // Wait for callback with timeout
            logger.info("⏳ Waiting for OAuth callback... (timeout: 5 minutes)")
            
            return try await withTimeout(seconds: 300) {
                return try await callbackServer.waitForCallback()
            }
            
        } catch let timeoutError where timeoutError is TimeoutError {
            // Cleanup on timeout
            await Self.oauthStateManager.cleanup()
            
            logger.warning("⏰ Browser authentication timed out after 5 minutes")
            return ToolResult.failure(error: "Authentication timed out. Please try again and complete the authorization within 5 minutes.")
            
        } catch {
            // Cleanup on error
            await Self.oauthStateManager.cleanup()
            
            logger.error("❌ Browser authentication failed: \(error)")
            return ToolResult.failure(error: "Browser authentication failed: \(error.localizedDescription)")
        }
    }
    
    private func executeSetSessionKey(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        guard let sessionKeyValue = arguments["session_key"] else {
            throw ToolError.missingParameter("session_key")
        }
        
        let sessionKey = "\(sessionKeyValue)"
        
        do {
            try await lastFMService.setSessionKey(sessionKey)
            
            let username = await lastFMService.getCurrentUsername()
            logger.info("Session key set successfully for user: \(username ?? "unknown")")
            
            let result = ResponseFormatters.formatAuthenticationResult(
                true,
                username: username
            )
            
            return ToolResult.success(data: result)
            
        } catch {
            logger.error("Failed to set session key: \(error)")
            return ToolResult.failure(error: "Failed to set session key: \(error.localizedDescription)")
        }
    }
    
    private func executeCheckAuthStatus(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        let isAuthenticated = await lastFMService.isAuthenticated()
        let hasSavedSession = await lastFMService.hasSavedSession()
        
        var result: [String: (any Sendable)] = [
            "authenticated": isAuthenticated,
            "has_saved_session": hasSavedSession,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        if isAuthenticated {
            if let username = await lastFMService.getCurrentUsername() {
                result["username"] = username
                result["message"] = "Authenticated as \(username)"
                
                if hasSavedSession {
                    result["session_source"] = "restored_from_storage"
                } else {
                    result["session_source"] = "current_session_only"
                }
            } else {
                result["message"] = "Authenticated but username unavailable"
            }
        } else {
            if hasSavedSession {
                result["message"] = "Not authenticated, but saved session available. Try restarting or use 'authenticate_browser'."
            } else {
                result["message"] = "Not authenticated. Use 'authenticate_browser' to authenticate."
            }
        }
        
        return ToolResult.success(data: result)
    }
    
    private func executeRestoreSession(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        logger.info("🔄 Attempting to restore session from saved data...")
        
        await lastFMService.restoreSessionIfAvailable()
        
        let isAuthenticated = await lastFMService.isAuthenticated()
        
        if isAuthenticated {
            let username = await lastFMService.getCurrentUsername()
            logger.info("✅ Session restored successfully for user: \(username ?? "unknown")")
            
            let result: [String: (any Sendable)] = [
                "restored": true,
                "authenticated": true,
                "username": username ?? "unknown",
                "message": "Session successfully restored from saved data",
                "timestamp": Date().timeIntervalSince1970
            ]
            
            return ToolResult.success(data: result)
        } else {
            logger.info("❌ No valid saved session found")
            
            let result: [String: (any Sendable)] = [
                "restored": false,
                "authenticated": false,
                "message": "No valid saved session found. Please authenticate using 'authenticate_browser'",
                "timestamp": Date().timeIntervalSince1970
            ]
            
            return ToolResult.success(data: result)
        }
    }
    
    private func executeLogout(arguments: [String: (any Sendable)]) async throws -> ToolResult {
        // Get current username before clearing session
        let currentUsername = await lastFMService.getCurrentUsername()
        
        // Clear session
        await lastFMService.clearSession()
        
        // Stop any running callback server
        await Self.oauthStateManager.cleanup()
        
        logger.info("User logged out successfully: \(currentUsername ?? "unknown")")
        
        let result: [String: (any Sendable)] = [
            "logged_out": true,
            "previous_user": currentUsername ?? "unknown",
            "message": "Successfully logged out from Last.fm",
            "timestamp": Date().timeIntervalSince1970
        ]
        
        return ToolResult.success(data: result)
    }
    
    // MARK: - Helper Methods
    
    private func generateAuthURL(callbackURL: String, state: String) -> String {
        let apiKey = lastFMService.getAPIKey()
        let encodedCallback = callbackURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? callbackURL
        
        return "https://www.last.fm/api/auth/?api_key=\(apiKey)&cb=\(encodedCallback)&state=\(state)"
    }
    
    private func openURL(_ urlString: String) {
        #if os(macOS) && canImport(AppKit)
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
        #elseif os(Linux)
        // Try common Linux browsers
        let browsers = ["xdg-open", "firefox", "chromium", "google-chrome", "brave"]
        for browser in browsers {
            let process = Process()
            process.launchPath = "/usr/bin/which"
            process.arguments = [browser]
            
            do {
                try process.run()
                process.waitUntilExit()
                
                if process.terminationStatus == 0 {
                    let openProcess = Process()
                    openProcess.launchPath = "/usr/bin/\(browser)"
                    openProcess.arguments = [urlString]
                    try openProcess.run()
                    break
                }
            } catch {
                continue
            }
        }
        #endif
    }
    
    private func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @Sendable @escaping () async throws -> T) async throws -> T {
        return try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                return try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Supporting Types

struct TimeoutError: Swift.Error, LocalizedError {
    var errorDescription: String? {
        return "Operation timed out"
    }
}

// MARK: - OAuth State Manager Actor

/// Thread-safe OAuth state management using Actor
actor OAuthStateManager: Sendable {
    private var callbackServer: OAuthCallbackServer?
    private var authState: String?
    
    func setCallbackServer(_ server: OAuthCallbackServer) {
        self.callbackServer = server
    }
    
    func getCallbackServer() -> OAuthCallbackServer? {
        return callbackServer
    }
    
    func setState(_ state: String) {
        self.authState = state
    }
    
    func getState() -> String? {
        return authState
    }
    
    func cleanup() async {
        if let server = callbackServer {
            await server.stop()
        }
        callbackServer = nil
        authState = nil
    }
}
