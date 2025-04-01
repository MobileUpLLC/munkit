//
//  TokenRefresher.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

actor TokenRefresher {
    private let tokenRefreshProvider: MUNKTokenProvider
    private var refreshTokenTask: _Concurrency.Task<Void, Error>?

    init(tokenRefreshProvider: MUNKTokenProvider) {
        self.tokenRefreshProvider = tokenRefreshProvider
    }

    func refreshToken() async throws {
        Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. RefreshToken method called"))

        if let task = refreshTokenTask {
            return try await task.value
        }

        refreshTokenTask = _Concurrency.Task { [weak self] in
            guard let self else { throw CancellationError() }

            Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. RefreshToken request started"))

            do {
                _ = try await tokenRefreshProvider.refreshToken()
                Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. RefreshToken updated"))
            } catch {
                Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. RefreshToken failed: \(error)"))
                throw error
            }
        }

        try await refreshTokenTask?.value
    }
}
