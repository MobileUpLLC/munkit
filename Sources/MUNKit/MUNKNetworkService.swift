//
//  MUNKNetworkService.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Moya

open class MUNKNetworkService<Target: MUNKMobileApiTargetType> {
    private var onTokenRefreshFailed: (() -> Void)? { didSet { onceExecutor = OnceExecutor() } }
    private let apiProvider: MoyaProvider<Target>
    private let tokenRefreshProvider: MUNKTokenProvider
    private var tokenRefresher: TokenRefresher { TokenRefresher(tokenRefreshProvider: tokenRefreshProvider) }
    private var onceExecutor: OnceExecutor?

    init(apiProvider: MoyaProvider<Target>, tokenRefreshProvider: MUNKTokenProvider) {
        self.apiProvider = apiProvider
        self.tokenRefreshProvider = tokenRefreshProvider
    }

    public func request<T: Decodable & Sendable>(target: Target) async throws -> T {
        print("NetworkService. Request \(target) started")

        do {
            return try await apiProvider.request(target: target)
        } catch {
            try _Concurrency.Task.checkCancellation()

            if target.isRefreshTokenRequest == false,
               let serverError = error as? MoyaError,
               serverError.errorCode == 403
            {
                try await refreshToken()

                print("NetworkService. Request \(target) started")

                return try await apiProvider.request(target: target)
            } else {
                print("NetworkService. Request \(target) failed with error \(error)")
                
                throw error
            }
        }
    }

    public func request(target: Target) async throws {
        print("NetworkService. Request \(target) started")

        do {
            return try await apiProvider.request(target: target)
        } catch {
            try _Concurrency.Task.checkCancellation()

            if target.isRefreshTokenRequest == false,
               let serverError = error as? MoyaError,
               serverError.errorCode == 403
            {
                try await refreshToken()

                print("NetworkService. Request \(target) started")

                return try await apiProvider.request(target: target)
            } else {
                print("NetworkService. Request \(target) failed with error \(error)")

                throw error
            }
        }
    }

    private func refreshToken() async throws {
        do {
            try await tokenRefresher.refreshToken()
        } catch let error {
            try _Concurrency.Task.checkCancellation()

            if let serverError = error as? MoyaError, serverError.errorCode == 403 || serverError.errorCode == 409 {
                await onceExecutor?.executeTokenRefreshFailed()
            }

            print("NetworkService. RefreshToken request failed. \(error)")
            throw error
        }
    }
}
