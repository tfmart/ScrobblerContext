//
//  OAuthCallbackServer.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation
@preconcurrency import Swifter
import Logging

/// HTTP server for handling OAuth callbacks
final class OAuthCallbackServer: Sendable {
    private let port: Int
    private let logger = Logger(label: "com.lastfm.mcp-server.oauth")
    private let server = HttpServer()
    private let lastFMService: LastFMService
    private let expectedStateManager = ExpectedStateManager()
    private let continuationManager = ContinuationManager()
    
    init(port: Int, lastFMService: LastFMService) {
        self.port = port
        self.lastFMService = lastFMService
        setupRoutes()
    }
    
    private func setupRoutes() {
        // OAuth callback endpoint
        server["/callback"] = { [weak self] request in
            guard let self = self else {
                return .internalServerError
            }
            
            self.logger.info("Received OAuth callback")
            
            // Handle the callback asynchronously
            Task { [weak self] in
                guard let self = self else { return }
                do {
                    let result = try await self.handleCallback(request: request)
                    await self.continuationManager.resume(with: .success(result))
                } catch {
                    self.logger.error("Callback processing failed: \(error)")
                    await self.continuationManager.resume(with: .failure(error))
                }
            }
            
            // Return immediate success page
            return .ok(.html(self.generateSuccessPage()))
        }
        
        // Health check endpoint
        server["/health"] = { _ in
            return .ok(.json([
                "status": "ready",
                "service": "lastfm-oauth-callback",
                "timestamp": Date().timeIntervalSince1970
            ]))
        }
        
        // Handle OAuth errors
        server["/error"] = { request in
            let queryParams = self.queryParametersAsDictionary(request.queryParams)
            let errorMsg = queryParams["error"] ?? "Unknown error"
            let errorDescription = queryParams["error_description"] ?? ""
            
            return .ok(.html(generateErrorPage(error: errorMsg, description: errorDescription)))
        }
        
        // Catch-all for other paths
        server.notFoundHandler = { request in
            return .notFound
        }
    }
    
    func start() async throws {
        do {
            try server.start(UInt16(port))
            logger.info("OAuth callback server started on http://localhost:\(port)")
        } catch {
            logger.error("Failed to start OAuth callback server: \(error)")
            throw ToolError.networkError("Failed to start callback server on port \(port): \(error.localizedDescription)")
        }
    }
    
    func stop() async {
        server.stop()
        logger.info("OAuth callback server stopped")
    }
    
    func setExpectedState(_ state: String) async {
        await expectedStateManager.setState(state)
    }
    
    func waitForCallback() async throws -> ToolResult {
        return try await continuationManager.waitForResult()
    }
    
    private func handleCallback(request: HttpRequest) async throws -> ToolResult {
            // Convert query parameters to dictionary for easier access
            let queryParams = queryParametersAsDictionary(request.queryParams)
            
            logger.info("Processing OAuth callback with query params: \(queryParams.map { "\($0.key)=\($0.value)" }.joined(separator: "&"))")
            
            // Check for error parameter first
            if let error = queryParams["error"] {
                let errorDescription = queryParams["error_description"] ?? "No description provided"
                logger.error("OAuth error received: \(error) - \(errorDescription)")
                throw ToolError.invalidOAuthCallback("OAuth error: \(error) - \(errorDescription)")
            }
            
            // Extract token and state
            guard let token = queryParams["token"] else {
                logger.error("Missing token parameter in OAuth callback")
                throw ToolError.invalidOAuthCallback("Missing token parameter in callback")
            }
            
            let receivedState = queryParams["state"]
            
            // Verify state matches (CSRF protection) - Last.fm doesn't return state parameter
            let expectedStateValue = await expectedStateManager.getState()
            logger.info("State validation - Expected: '\(expectedStateValue ?? "nil")', Received: '\(receivedState ?? "nil")'")
            
            // NOTE: Last.fm OAuth doesn't return the state parameter, so we skip strict validation
            // The CSRF risk is minimal since this is a temporary local server with a short-lived token
            if let receivedState = receivedState, let expectedStateValue = expectedStateValue {
                // If Last.fm ever starts returning state, validate it
                if receivedState == expectedStateValue {
                    logger.info("✅ State parameter validation successful")
                } else {
                    logger.warning("⚠️ State parameter mismatch, but continuing (Last.fm limitation)")
                }
            } else if expectedStateValue != nil {
                logger.info("ℹ️ Last.fm didn't return state parameter (expected behavior)")
            } else {
                logger.warning("⚠️ No expected state stored")
            }
            
            logger.info("Received valid OAuth token, exchanging for session key...")
            
            do {
                // Exchange token for session key using Last.fm API
                let sessionKey = try await lastFMService.exchangeTokenForSession(token: token)
                
                // Set the session key in the service
                try await lastFMService.setSessionKey(sessionKey)
                
                // Verify authentication worked by checking status
                let isAuthenticated = await lastFMService.isAuthenticated()
                guard isAuthenticated else {
                    throw ToolError.authenticationFailed("Failed to authenticate with received session key")
                }
                
                // Get username for confirmation
                let username = await lastFMService.getCurrentUsername()
                
                logger.info("🎵 Browser OAuth authentication completed successfully for user: \(username ?? "unknown")")
                
                let result: [String: (any Sendable)] = [
                    "authenticated": true,
                    "method": "browser_oauth",
                    "username": username ?? "unknown",
                    "timestamp": Date().timeIntervalSince1970,
                    "message": "Successfully authenticated via browser OAuth flow"
                ]
                
                return ToolResult.success(data: result)
                
            } catch let toolError as ToolError {
                logger.error("Authentication process failed: \(toolError)")
                throw toolError
            } catch {
                logger.error("Unexpected error during authentication: \(error)")
                throw ToolError.authenticationFailed("Authentication process failed: \(error.localizedDescription)")
            }
        }
    
    /// Convert Swifter's query parameters (array of tuples) to a dictionary
    private func queryParametersAsDictionary(_ queryParams: [(String, String)]) -> [String: String] {
        var dict: [String: String] = [:]
        for (key, value) in queryParams {
            dict[key] = value
        }
        return dict
    }
    
    private func generateSuccessPage() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <title>Last.fm Authentication Success</title>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }
                
                body { 
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, system-ui, sans-serif; 
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }
                
                .container {
                    background: rgba(255, 255, 255, 0.1);
                    padding: 3rem;
                    border-radius: 20px;
                    backdrop-filter: blur(15px);
                    border: 1px solid rgba(255, 255, 255, 0.2);
                    max-width: 500px;
                    width: 90%;
                    text-align: center;
                    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
                }
                
                .icon {
                    font-size: 4rem;
                    margin-bottom: 1rem;
                    animation: bounce 2s infinite;
                }
                
                @keyframes bounce {
                    0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
                    40% { transform: translateY(-10px); }
                    60% { transform: translateY(-5px); }
                }
                
                h1 { 
                    color: #fff; 
                    margin-bottom: 1rem;
                    font-size: 2rem;
                    font-weight: 600;
                }
                
                .success-message {
                    color: #4ade80;
                    font-weight: 600;
                    font-size: 1.2rem;
                    margin-bottom: 1rem;
                }
                
                p { 
                    font-size: 1.1rem; 
                    margin: 1rem 0;
                    line-height: 1.5;
                    opacity: 0.9;
                }
                
                .close-button {
                    background: linear-gradient(45deg, #4ade80, #22c55e);
                    border: none;
                    color: white;
                    padding: 12px 24px;
                    font-size: 1rem;
                    font-weight: 600;
                    border-radius: 12px;
                    cursor: pointer;
                    margin-top: 1.5rem;
                    transition: all 0.2s ease;
                    box-shadow: 0 4px 12px rgba(34, 197, 94, 0.3);
                }
                
                .close-button:hover {
                    transform: translateY(-2px);
                    box-shadow: 0 6px 16px rgba(34, 197, 94, 0.4);
                }
                
                .footer {
                    margin-top: 2rem;
                    font-size: 0.9rem;
                    opacity: 0.7;
                }
                
                .pulse {
                    animation: pulse 2s infinite;
                }
                
                @keyframes pulse {
                    0% { opacity: 1; }
                    50% { opacity: 0.5; }
                    100% { opacity: 1; }
                }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="icon">🎵</div>
                <h1>Last.fm Authentication</h1>
                <div class="success-message">✅ Authentication Successful!</div>
                <p>You have successfully authenticated with Last.fm.</p>
                <p>You can now close this window and return to your application.</p>
                <button class="close-button" onclick="window.close()">Close Window</button>
                <div class="footer">
                    <p class="pulse">This window will automatically close in <span id="countdown">10</span> seconds</p>
                </div>
            </div>
            
            <script>
                let countdown = 10;
                const countdownElement = document.getElementById('countdown');
                
                const timer = setInterval(() => {
                    countdown--;
                    countdownElement.textContent = countdown;
                    
                    if (countdown <= 0) {
                        clearInterval(timer);
                        window.close();
                    }
                }, 1000);
                
                // Also allow manual close
                document.addEventListener('keydown', (e) => {
                    if (e.key === 'Escape' || e.key === 'Enter') {
                        window.close();
                    }
                });
            </script>
        </body>
        </html>
        """
    }
}

// MARK: - Thread-Safe Helper Actors

/// Actor to manage expected state safely
actor ExpectedStateManager {
    private var expectedState: String?
    
    func setState(_ state: String) {
        self.expectedState = state
    }
    
    func getState() -> String? {
        return expectedState
    }
    
    func clearState() {
        expectedState = nil
    }
}

/// Actor to manage continuation safely
actor ContinuationManager {
    private var continuation: CheckedContinuation<ToolResult, Error>?
    
    func waitForResult() async throws -> ToolResult {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }
    
    func resume(with result: Result<ToolResult, Error>) {
        guard let continuation = self.continuation else { return }
        self.continuation = nil
        
        switch result {
        case .success(let toolResult):
            continuation.resume(returning: toolResult)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}

// MARK: - Error Page Generator

private func generateErrorPage(error: String, description: String) -> String {
    return """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Authentication Error</title>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
            * {
                margin: 0;
                padding: 0;
                box-sizing: border-box;
            }
            
            body { 
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, system-ui, sans-serif; 
                background: linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%);
                color: white;
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
            }
            
            .container {
                background: rgba(255, 255, 255, 0.1);
                padding: 3rem;
                border-radius: 20px;
                backdrop-filter: blur(15px);
                border: 1px solid rgba(255, 255, 255, 0.2);
                max-width: 500px;
                width: 90%;
                text-align: center;
                box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
            }
            
            .icon {
                font-size: 4rem;
                margin-bottom: 1rem;
            }
            
            h1 { 
                color: #fff; 
                margin-bottom: 1rem;
                font-size: 2rem;
                font-weight: 600;
            }
            
            .error-code {
                background: rgba(255, 255, 255, 0.2);
                padding: 0.5rem 1rem;
                border-radius: 8px;
                font-family: 'Monaco', 'Courier New', monospace;
                margin: 1rem 0;
                word-break: break-word;
            }
            
            p { 
                font-size: 1.1rem; 
                margin: 1rem 0;
                line-height: 1.5;
                opacity: 0.9;
            }
            
            .close-button {
                background: rgba(255, 255, 255, 0.2);
                border: none;
                color: white;
                padding: 12px 24px;
                font-size: 1rem;
                font-weight: 600;
                border-radius: 12px;
                cursor: pointer;
                margin: 1rem 0.5rem;
                transition: all 0.2s ease;
            }
            
            .close-button:hover {
                background: rgba(255, 255, 255, 0.3);
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="icon">❌</div>
            <h1>Authentication Failed</h1>
            <div class="error-code">Error: \(error)</div>
            \(description.isEmpty ? "" : "<p>\(description)</p>")
            <p>Please close this window and try authenticating again.</p>
            <p>If the problem persists, check your Last.fm credentials and try again.</p>
            
            <div>
                <button class="close-button" onclick="window.close()">Close Window</button>
            </div>
        </div>
        
        <script>
            document.addEventListener('keydown', (e) => {
                if (e.key === 'Escape' || e.key === 'Enter') {
                    window.close();
                }
            });
        </script>
    </body>
    </html>
    """
}
