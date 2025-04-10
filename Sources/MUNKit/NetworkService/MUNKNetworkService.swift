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
    private var tokenRefreshTask: _Concurrency.Task<Void, Error>?
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
        print("🕸️ Request \(target) started. Wait \(T.self)")

        do {
            return try await performRequest(target: target)
        } catch {
            try await handleTokenRefresh(error, target: target)
            print("🕸️ Request \(target) updated token and will be performed again")
            return try await performRequest(target: target)
        }
    }

    public func request(target: Target) async throws {
        print("🕸️ Request \(target) started")

        do {
            try await performRequest(target: target)
        } catch {
            try await handleTokenRefresh(error, target: target)
            print("🕸️ Request \(target) updated token and will be performed again")
            try await performRequest(target: target)
        }
    }

    private func performRequest<T: Decodable & Sendable>(target: Target) async throws -> T {
        let result: T = try await withCheckedThrowingContinuation { continuation in
            apiProvider.request(target) { result in
                switch result {
                case .success(let response):
                    do {
                        let filteredResponse = try response.filterSuccessfulStatusCodes()
                        let decodedResponse = try filteredResponse.map(T.self)
                        continuation.resume(returning: decodedResponse)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
        return result
    }

    private func performRequest(target: Target) async throws {
        try await withCheckedThrowingContinuation { continuation in
            apiProvider.request(target) { result in
                switch result {
                case .success(let response):
                    do {
                        let _ = try response.filterSuccessfulStatusCodes()
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func handleTokenRefresh(_ error: Error, target: Target) async throws {
        try _Concurrency.Task.checkCancellation()

        guard let serverError = error as? MoyaError,
              let statusCode = serverError.response?.statusCode,
              unauthorizedStatusCodes.contains(statusCode) else {
            print("🕸️ Request \(target) failed with error \(error)")
            throw error
        }

        if let refreshTask = tokenRefreshTask {
            print("🕸️ Waiting for token refresh to complete for \(target)")
            try await refreshTask.value
            return
        }

        if target.isRefreshTokenRequest {
            try await refreshToken()
        } else {
            tokenRefreshTask = _Concurrency.Task {
                defer { tokenRefreshTask = nil }
                try await refreshToken()
            }
            try await tokenRefreshTask?.value
        }
    }

    private func refreshToken() async throws {
        print("🕸️ Start token refreshing")

        do {
            try await tokenRefresher.refreshToken()
            print("🕸️ Token refreshed")
        } catch {
            print("🕸️ Token refreshed with error: \(error)")

            if let serverError = error as? MoyaError,
               let statusCode = serverError.response?.statusCode,
               unauthorizedStatusCodes.contains(statusCode) {
                if await onceExecutor?.shouldExecuteTokenRefreshFailed() == true {
                    onTokenRefreshFailed?()
                    print("🕸️ onTokenRefreshFailed performed")
                }
            }
            throw error
        }
    }
}
