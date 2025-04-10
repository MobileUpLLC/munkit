//
//  MUNKNetworkService.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Moya

public actor MUNKNetworkService<Target: MUNKMobileApiTargetType> {
    private var onTokenRefreshFailed: (() -> Void)?
    private let apiProvider: MoyaProvider<Target>
    private let tokenRefresher: NetworkServiceTokenRefresher
    private var onceExecutor: NetworkServiceRefreshTokenActionOnceExecutor?
    private let unauthorizedStatusCodes: Set<Int> = [401, 403, 409]

    public init(apiProvider: MoyaProvider<Target>, tokenRefreshProvider: MUNKTokenProvider) {
        self.apiProvider = apiProvider
        self.tokenRefresher = NetworkServiceTokenRefresher(tokenRefreshProvider: tokenRefreshProvider)
    }

    public func setTokenRefreshFailedAction(_ action: @escaping () -> Void) {
        onTokenRefreshFailed = action
        onceExecutor = NetworkServiceRefreshTokenActionOnceExecutor()
    }

    public func request<T: Decodable & Sendable>(target: Target) async throws -> T {
        print("🕸️ Request \(target.logDescription). Starting with expected response type: \(T.self).")

        switch await performRequest(target: target) {
        case .success(let response):
            let filteredResponse = try response.filterSuccessfulStatusCodes()
            let result = try filteredResponse.map(T.self)
            print("🕸️ Request \(target.logDescription). Completed successfully.")
            return result
        case .failure(let error):
            print("🕸️ Request \(target.logDescription). Failed with error: \(error.localizedDescription).")
            try await updateTokenIfNeeded(error, target: target)
            return try await request(target: target)
        }
    }

    public func request(target: Target) async throws {
        print("🕸️ Request \(target.logDescription). Starting.")

        switch await performRequest(target: target) {
        case .success(let response):
            let _ = try response.filterSuccessfulStatusCodes()
            print("🕸️ Request \(target.logDescription). Completed successfully.")
            return
        case .failure(let error):
            print(
                """
                🕸️ Request \(target.logDescription). 
                Failed with error: \(error.localizedDescription). 
                Attempting to refresh token.
                """
            )
            try await updateTokenIfNeeded(error, target: target)
            print("🕸️ Request \(target.logDescription). Token refreshed, retrying.")
            return try await request(target: target)
        }
    }

    private func performRequest(target: Target) async -> Result<Response, MoyaError> {
        return await withCheckedContinuation { continuation in
            apiProvider.request(target) { continuation.resume(returning: $0) }
        }
    }

    private func updateTokenIfNeeded(_ error: Error, target: Target) async throws {
        print("🕸️ Request \(target.logDescription). Checking if token refresh is needed.")

        guard
            let serverError = error as? MoyaError,
            let statusCode = serverError.response?.statusCode,
            unauthorizedStatusCodes.contains(statusCode)
        else {
            print(
                """
                🕸️ Request \(target.logDescription). Failed without token refresh. 
                Error: \(error.localizedDescription).
                """
            )
            throw error
        }

        if target.isRefreshTokenRequest {
            try await refreshToken(target: target)
        }
    }

    private func refreshToken(target: Target) async throws {
        print("🕸️ Request \(target.logDescription). Initiating token refresh.")

        do {
            try await tokenRefresher.refreshToken()
            print("🕸️ Request \(target.logDescription). Token refreshed successfully.")
        } catch {
            print(
                """
                🕸️ Request \(target.logDescription).
                Token refresh failed with error: \(error.localizedDescription).
                """
            )

            if
                let serverError = error as? MoyaError,
                let statusCode = serverError.response?.statusCode,
                unauthorizedStatusCodes.contains(statusCode)
            {
                if await onceExecutor?.shouldExecuteTokenRefreshFailed() == true {
                    onTokenRefreshFailed?()
                    print("🕸️ Request \(target.logDescription). Executed token refresh failure action.")
                }
            }

            throw error
        }
    }
}
