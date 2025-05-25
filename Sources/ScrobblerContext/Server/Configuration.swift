//
//  Configuration.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 17/05/25.
//

import Foundation

struct Configuration {
    let apiKey: String
    let secretKey: String
    let serverName: String
    let serverVersion: String
    
    init() throws {
        guard let apiKey = ProcessInfo.processInfo.environment["LASTFM_API_KEY"],
              !apiKey.isEmpty else {
            throw ConfigurationError.missingEnvironmentVariable("LASTFM_API_KEY")
        }
        
        guard let secretKey = ProcessInfo.processInfo.environment["LASTFM_SECRET_KEY"],
              !secretKey.isEmpty else {
            throw ConfigurationError.missingEnvironmentVariable("LASTFM_SECRET_KEY")
        }
        
        self.apiKey = apiKey
        self.secretKey = secretKey
        self.serverName = "ScrobblerContext - Last.fm MCP Server"
        self.serverVersion = "1.0.0"
    }
}
