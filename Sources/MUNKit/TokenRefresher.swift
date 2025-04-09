//
//  TokenRefresher.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

actor TokenRefresher {
    private let tokenRefreshProvider: MUNKTokenProvider
    private var refreshTokenTask: Task<Void, Error>?

    init(tokenRefreshProvider: MUNKTokenProvider) {
        self.tokenRefreshProvider = tokenRefreshProvider
    }

    func refreshToken() async throws {
        print("NetworkService. RefreshToken method called")

        if let task = refreshTokenTask {
            return try await task.value
        }

        refreshTokenTask = Task { [weak self] in
            guard let self else {
                throw CancellationError()
            }

            print("NetworkService. RefreshToken request started")

            do {
                _ = try await tokenRefreshProvider.refreshToken()
                print("NetworkService. RefreshToken updated")
            } catch {
                print("NetworkService. RefreshToken failed: \(error)")
                throw error
            }
        }

        try await refreshTokenTask?.value
    }
}
