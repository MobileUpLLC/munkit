//
//  MUNKNetworkService.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Moya

open class MUNKNetworkService<Target: MUNKMobileApiTargetType> {
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
        print("NetworkService. Request \(target) started")

        do {
            return try await performRequest(target: target)
        } catch {
            try await checkErrorAndRefreshTokenIfNeeded(error, target: target)
            print("NetworkService. Request \(target) started after token refresh")
            return try await performRequest(target: target)
        }
    }

    public func request(target: Target) async throws {
        print("NetworkService. Request \(target) started")

        do {
            return try await performRequest(target: target)
        } catch {
            try await checkErrorAndRefreshTokenIfNeeded(error, target: target)
            print("NetworkService. Request \(target) started after token refresh")
            return try await performRequest(target: target)
        }
    }

    private func checkErrorAndRefreshTokenIfNeeded(_ error: Error, target: Target) async throws {
        try _Concurrency.Task.checkCancellation()

        if target.isRefreshTokenRequest == false,
           let serverError = error as? MoyaError,
           serverError.errorCode == 403 {
            try await refreshToken()
        } else {
            print("NetworkService. Request \(target) failed with error \(error)")
            throw error
        }
    }

    private func refreshToken() async throws {
        guard isTokenRefreshAttempted == false else {
            print("NetworkService. Token refresh attempt was already made")
            throw CancellationError()
        }

        isTokenRefreshAttempted = true

        do {
            try await tokenRefresher.refreshToken()
        } catch let error {
            try _Concurrency.Task.checkCancellation()

            if let serverError = error as? MoyaError, serverError.errorCode == 403 || serverError.errorCode == 409 {
                if await onceExecutor?.shouldExecuteTokenRefreshFailed() == true {
                    onTokenRefreshFailed?()
                    print("NetworkService. Send onTokenRefreshFailed")
                }
            }

            print("NetworkService. RefreshToken request failed. \(error)")
            throw error
        }
    }

    private func performRequest<T: Decodable & Sendable>(target: Target) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            apiProvider.request(target) { [weak self] result in
                switch result {
                case .success(let response):
                    if target.isAccessTokenRequired {
                        self?.isTokenRefreshAttempted = false
                    }
                    self?.handleRequestSuccess(response: response, continuation: continuation)
                case .failure(let error):
                    self?.handleRequestFailure(error: error, continuation: continuation)
                }
            }
        }
    }

    private func performRequest(target: Target) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            apiProvider.request(target) { [weak self] result in
                switch result {
                case .success(let response):
                    if target.isAccessTokenRequired {
                        self?.isTokenRefreshAttempted = false
                    }
                    self?.handleRequestSuccess(response: response, continuation: continuation)
                case .failure(let error):
                    self?.handleRequestFailure(error: error, continuation: continuation)
                }
            }
        }
    }

    private func handleRequestSuccess<T: Decodable & Sendable>(response: Response, continuation: CheckedContinuation<T, Error>) {
        do {
            let filteredResponse = try response.filterSuccessfulStatusCodes()
            let decodedResponse = try filteredResponse.map(T.self)

            continuation.resume(returning: decodedResponse)
        } catch let error {
            continuation.resume(throwing: error)
        }
    }

    private func handleRequestSuccess(response: Response, continuation: CheckedContinuation<Void, Error>) {
        do {
            _ = try response.filterSuccessfulStatusCodes()
            continuation.resume()
        } catch let error {
            continuation.resume(throwing: error)
        }
    }

    private func handleRequestFailure<T: Decodable>(error: MoyaError, continuation: CheckedContinuation<T, Error>) {
        continuation.resume(throwing: error)
    }

    private func handleRequestFailure(error: MoyaError, continuation: CheckedContinuation<Void, Error>) {
        continuation.resume(throwing: error)
    }
}
