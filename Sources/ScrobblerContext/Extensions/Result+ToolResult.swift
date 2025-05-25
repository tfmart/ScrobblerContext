//
//  Result+ToolResult.swift
//  ScrobblerContext
//
//  Created by Tomas Martins on 25/05/25.
//

import Foundation

extension Result where Success == ToolResult, Failure == Error {
    /// Convert Result to ToolResult for consistent error handling
    func toToolResult() -> ToolResult {
        switch self {
        case .success(let toolResult):
            return toolResult
        case .failure(let error):
            return ToolResult.failure(error: error.localizedDescription)
        }
    }
}
