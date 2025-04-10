//
//  NetworkServiceRefreshTokenActionOnceExecutor.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

actor NetworkServiceRefreshTokenActionOnceExecutor {
    private var hasRun = false

    func shouldExecuteTokenRefreshFailed() -> Bool {
        guard !hasRun else {
            return false
        }
        hasRun = true
        return true
    }
}
