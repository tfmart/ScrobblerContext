//
//  MCPServer.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 17/05/25.
//

import Foundation
import MCP
import Logging

/// Main MCP Server for Last.fm integration
final class MCPServer: Sendable {
    private let configuration: Configuration
    private let lastFMService: LastFMService
    private let toolExecutor: ToolExecutor
    private let server: Server
    private let logger = Logger(label: "com.lastfm.mcp-server")
    
    init() throws {
        // Load configuration
        self.configuration = try Configuration()
        
        // Initialize Last.fm service
        self.lastFMService = LastFMService(
            apiKey: configuration.apiKey,
            secretKey: configuration.secretKey
        )
        
        // Initialize tool registry and executor
        let toolRegistry = ToolRegistry(lastFMService: lastFMService)
        self.toolExecutor = ToolExecutor(toolRegistry: toolRegistry)
        
        // Create MCP server
        self.server = Server(
            name: configuration.serverName,
            version: configuration.serverVersion,
            capabilities: .init(tools: .init(listChanged: false))
        )
        
        logger.info("MCP Server initialized with name: \(configuration.serverName)")
    }
    
    // MARK: - Server Lifecycle
    
    func start() async throws {
        logger.info("Starting Last.fm MCP Server...")
        
        // Validate Last.fm service connection
        try await validateService()
 
        // Register handlers
        await registerHandlers()
        
        // Start with stdio transport
        let transport = StdioTransport(logger: logger)
        try await server.start(transport: transport)
        
        logger.info("Server started successfully and listening on stdio")
    }
    
    func waitForCompletion() async {
        logger.info("Server running, waiting for completion...")
        await server.waitUntilCompleted()
        logger.info("Server completed")
    }
    
    // MARK: - Handler Registration
    
    private func registerHandlers() async {
        await registerToolListHandler()
        await registerToolCallHandler()
        
        logger.info("All MCP handlers registered successfully")
    }
    
    private func registerToolListHandler() async {
        await server.withMethodHandler(ListTools.self) { [weak self] params in
            guard let self = self else {
                throw MCPError.internalError("Server instance not available")
            }
            
            self.logger.info("Handling tool list request")
            let tools = self.toolExecutor.getAvailableTools()
            
            self.logger.info("Returning \(tools.count) available tools")
            return ListTools.Result(tools: tools)
        }
    }
    
    private func registerToolCallHandler() async {
        await server.withMethodHandler(CallTool.self) { [weak self] params in
            guard let self = self else {
                throw MCPError.internalError("Server instance not available")
            }
            
            self.logger.info("Handling tool call: \(params.name)")
            
            // Validate arguments before execution
            do {
                try self.toolExecutor.validateToolArguments(
                    toolName: params.name,
                    arguments: params.arguments ?? [:]
                )
            } catch {
                self.logger.error("Tool argument validation failed: \(error)")
                throw MCPError.invalidParams("Invalid arguments: \(error.localizedDescription)")
            }
            
            // Execute the tool
            return try await self.toolExecutor.execute(
                toolName: params.name,
                arguments: params.arguments
            )
        }
    }
    
    // MARK: - Service Validation
    
    private func validateService() async throws {
        logger.info("Validating Last.fm service connection...")
        
        do {
            try await lastFMService.validateService()
            logger.info("✅ Last.fm service validation successful")
        } catch {
            logger.error("❌ Last.fm service validation failed: \(error)")
            throw error
        }
    }
}
