//
//  SessionPersistenceManager.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation
import Security
import Logging

/// Manages secure persistence of Last.fm session data
actor SessionPersistenceManager {
    private let logger = Logger(label: "com.lastfm.mcp-server.session")
    
    // Keychain configuration
    private let service = "com.lastfm.mcp-server"
    private let sessionKeyAccount = "lastfm-session-key"
    private let usernameAccount = "lastfm-username"
    
    // MARK: - Public Interface
    
    /// Save session data securely
    func saveSession(sessionKey: String, username: String) async throws {
        try await saveToKeychain(account: sessionKeyAccount, data: sessionKey)
        try await saveToKeychain(account: usernameAccount, data: username)
        logger.info("✅ Session saved securely for user: \(username)")
    }
    
    /// Load saved session data
    func loadSession() async throws -> (sessionKey: String, username: String)? {
        guard let sessionKey = try await loadFromKeychain(account: sessionKeyAccount),
              let username = try await loadFromKeychain(account: usernameAccount) else {
            logger.info("🔍 No saved session found")
            return nil
        }
        
        logger.info("📥 Loaded saved session for user: \(username)")
        return (sessionKey: sessionKey, username: username)
    }
    
    /// Clear saved session data
    func clearSession() async throws {
        try await deleteFromKeychain(account: sessionKeyAccount)
        try await deleteFromKeychain(account: usernameAccount)
        logger.info("🗑️ Session data cleared")
    }
    
    /// Check if session data exists
    func hasSession() async -> Bool {
        do {
            let sessionKey = try await loadFromKeychain(account: sessionKeyAccount)
            return sessionKey != nil
        } catch {
            return false
        }
    }
    
    // MARK: - Keychain Operations
    
    private func saveToKeychain(account: String, data: String) async throws {
        let dataToStore = data.data(using: .utf8)!
        
        // First, try to update existing item
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let updateAttributes: [String: Any] = [
            kSecValueData as String: dataToStore
        ]
        
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
        
        if updateStatus == errSecSuccess {
            logger.debug("Updated existing keychain item for account: \(account)")
            return
        }
        
        // If update failed, add new item
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: dataToStore,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        
        guard addStatus == errSecSuccess else {
            logger.error("Failed to save to keychain: \(addStatus)")
            throw SessionPersistenceError.keychainError("Failed to save session data")
        }
        
        logger.debug("Added new keychain item for account: \(account)")
    }
    
    private func loadFromKeychain(account: String) async throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            logger.error("Failed to load from keychain: \(status)")
            throw SessionPersistenceError.keychainError("Failed to load session data")
        }
        
        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw SessionPersistenceError.keychainError("Invalid keychain data format")
        }
        
        return string
    }
    
    private func deleteFromKeychain(account: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            logger.error("Failed to delete from keychain: \(status)")
            throw SessionPersistenceError.keychainError("Failed to delete session data")
        }
    }
}

// MARK: - Fallback File-Based Storage (for non-Keychain platforms)

#if !os(macOS) && !os(iOS)
extension SessionPersistenceManager {
    
    /// Fallback storage directory
    private var storageDirectory: URL {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let configDir = homeDir.appendingPathComponent(".config/lastfm-mcp-server")
        
        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        
        return configDir
    }
    
    /// Save session using file-based storage (fallback)
    private func saveToFile(filename: String, data: String) async throws {
        let fileURL = storageDirectory.appendingPathComponent(filename)
        
        // Simple encryption using base64 encoding (better than plaintext)
        let encodedData = data.data(using: .utf8)?.base64EncodedData()
        
        try encodedData?.write(to: fileURL, options: [.atomic, .completeFileProtection])
        
        // Set file permissions to be readable only by owner
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }
    
    /// Load session from file-based storage (fallback)
    private func loadFromFile(filename: String) async throws -> String? {
        let fileURL = storageDirectory.appendingPathComponent(filename)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        let encodedData = try Data(contentsOf: fileURL)
        guard let decodedData = Data(base64Encoded: encodedData),
              let string = String(data: decodedData, encoding: .utf8) else {
            throw SessionPersistenceError.fileError("Invalid session file format")
        }
        
        return string
    }
    
    /// Delete session file (fallback)
    private func deleteFile(filename: String) async throws {
        let fileURL = storageDirectory.appendingPathComponent(filename)
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            try FileManager.default.removeItem(at: fileURL)
        }
    }
}
#endif

// MARK: - Session Persistence Errors

enum SessionPersistenceError: Error, LocalizedError {
    case keychainError(String)
    case fileError(String)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .keychainError(let message):
            return "Keychain error: \(message)"
        case .fileError(let message):
            return "File storage error: \(message)"
        case .invalidData:
            return "Invalid session data format"
        }
    }
}
