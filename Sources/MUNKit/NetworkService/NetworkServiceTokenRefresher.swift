//
//  NetworkServiceTokenRefresher.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

actor NetworkServiceTokenRefresher {
    private let tokenRefreshProvider: MUNKTokenProvider
    private var refreshTokenTask: Task<Void, Error>?

    init(tokenRefreshProvider: MUNKTokenProvider) {
        self.tokenRefreshProvider = tokenRefreshProvider
    }

    func refreshToken() async throws {
        if let task = refreshTokenTask {
            return try await task.value
        }

        refreshTokenTask = Task { [weak self] in
            guard let self else {
                throw CancellationError()
            }

            do {
                _ = try await tokenRefreshProvider.refreshToken()
            } catch {
                throw error
            }
        }

        try await refreshTokenTask?.value
        refreshTokenTask = nil
    }
}
