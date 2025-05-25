//
//  SessionManager.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

/// Thread-safe session management using Actor
actor SessionManager {
    private var sessionKey: String?
    private var username: String?
    
    func setSessionKey(_ key: String) {
        self.sessionKey = key
    }
    
    func getSessionKey() -> String? {
        return sessionKey
    }
    
    func setUsername(_ name: String) {
        self.username = name
    }
    
    func getUsername() -> String? {
        return username
    }
    
    func clearSession() {
        sessionKey = nil
        username = nil
    }
}
