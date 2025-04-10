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
    private var isTokenRefreshAttempted = false

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
            try await checkErrorAndRefreshTokenIfNeeded(error, target: target)
            return try await performRequest(target: target)
        }
    }

    public func request(target: Target) async throws {
        print("🕸️ Request \(target) started")

        do {
            return try await performRequest(target: target)
        } catch {
            try await checkErrorAndRefreshTokenIfNeeded(error, target: target)
            return try await performRequest(target: target)
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
        if target.isAccessTokenRequired {
            self.isTokenRefreshAttempted = false
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
        if target.isAccessTokenRequired {
            self.isTokenRefreshAttempted = false
        }
    }

    private func checkErrorAndRefreshTokenIfNeeded(_ error: Error, target: Target) async throws {
        try _Concurrency.Task.checkCancellation()

        if
            target.isRefreshTokenRequest == false,
            let serverError = error as? MoyaError,
            serverError.errorCode == 403
        {
            try await refreshToken()
        } else {
            print("🕸️ Request \(target) failed with error \(error)")
            throw error
        }
    }

    private func refreshToken() async throws {
        guard isTokenRefreshAttempted == false else {
            print("🕸️ Token refresh attempt was already made")
            throw CancellationError()
        }

        print("🕸️ Start token refreshing")

        isTokenRefreshAttempted = true

        do {
            try await tokenRefresher.refreshToken()
            print("🕸️ Token refreshed")
        } catch let error {
            print("🕸️ Token refreshed with error: \(error)")

            if let serverError = error as? MoyaError, serverError.errorCode == 403 || serverError.errorCode == 409 {
                if await onceExecutor?.shouldExecuteTokenRefreshFailed() == true {
                    onTokenRefreshFailed?()
                    print("🕸️ onTokenRefreshFailed performed")
                }
            }

            throw error
        }
    }
}
