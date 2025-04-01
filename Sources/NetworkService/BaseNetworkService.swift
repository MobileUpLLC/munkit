//
//  BaseNetworkService.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Moya

open class BaseNetworkService<Target: MobileApiTargetType> {
    public var onTokenRefreshFailed: (() -> Void)? { didSet { onceExecutor = OnceExecutor() } }

    public let apiProvider: MoyaProvider<Target>
    public let tokenRefreshProvider: MUNKTokenProvider

    private var tokenRefresher: TokenRefresher { TokenRefresher(tokenRefreshProvider: tokenRefreshProvider) }
    private var onceExecutor: OnceExecutor?

    public init(apiProvider: MoyaProvider<Target>, tokenRefreshProvider: MUNKTokenProvider) {
        self.apiProvider = apiProvider
        self.tokenRefreshProvider = tokenRefreshProvider
    }

    public func request<T: Decodable & Sendable>(target: Target) async throws -> T {
        Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. Request \(target) started"))

        do {
            return try await apiProvider.request(target: target)
        } catch {
            try _Concurrency.Task.checkCancellation()

            if target.isRefreshTokenRequest == false,
               let serverError = error as? MoyaError,
               serverError.errorCode == 403
            {
                try await refreshToken()

                Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. Request \(target) started"))

                return try await apiProvider.request(target: target)
            } else {
                let logText = "NetworkService. Request \(target) failed with error \(error)"
                Log.refreshTokenFlow.debug(logEntry: .text(logText))
                throw error
            }
        }
    }

    public func request(target: Target) async throws {
        Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. Request \(target) started"))

        do {
            return try await apiProvider.request(target: target)
        } catch {
            try _Concurrency.Task.checkCancellation()

            if target.isRefreshTokenRequest == false,
               let serverError = error as? MoyaError,
               serverError.errorCode == 403
            {
                try await refreshToken()

                Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. Request \(target) started"))

                return try await apiProvider.request(target: target)
            } else {
                let logText = "NetworkService. Request \(target) failed with error \(error)"
                Log.refreshTokenFlow.debug(logEntry: .text(logText))

                throw error
            }
        }
    }

    private func refreshToken() async throws {
        do {
            try await tokenRefresher.refreshToken()
        } catch let error {
            try _Concurrency.Task.checkCancellation()

            if let serverError = error as? MoyaError, serverError.errorCode == 403 {
                await onceExecutor?.executeTokenRefreshFailed()
            }

            if let serverError = error as? MoyaError, serverError.errorCode == 409 {
                await onceExecutor?.executeTokenRefreshFailed()
            }

            Log.refreshTokenFlow.debug(logEntry: .text("NetworkService. RefreshToken request failed. \(error)"))
            throw error
        }
    }
}
