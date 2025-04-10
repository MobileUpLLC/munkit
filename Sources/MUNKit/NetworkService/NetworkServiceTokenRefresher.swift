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
            print("🕸️ Wait token refreshing results")

            try await task.value

            print("🕸️ Token refreshing results will be used")

            return
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

        print("🕸️ Refresh token task added")

        try await refreshTokenTask?.value
        refreshTokenTask = nil
    }
}
