//
//  ToolResult.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 17/05/25.
//

import Foundation

struct ToolResult {
    let success: Bool
    let data: [String: Any]?
    let error: String?
    
    static func success(data: [String: Any]) -> ToolResult {
        return ToolResult(success: true, data: data, error: nil)
    }
    
    static func failure(error: String) -> ToolResult {
        return ToolResult(success: false, data: nil, error: error)
    }
    
    func toJSON() throws -> String {
        var result: [String: Any] = ["success": success]
        
        if let data = data {
            result.merge(data) { _, new in new }
        }
        
        if let error = error {
            result["error"] = error
        }
        
        let jsonData = try JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted])
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ToolError.jsonSerializationFailed
        }
        return jsonString
    }
}
