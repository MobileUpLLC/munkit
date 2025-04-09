//
//  MUNKNetworkService.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Moya

open class MUNKNetworkService<Target: MUNKMobileApiTargetType> {
    private var onTokenRefreshFailed: (() -> Void)? { didSet { onceExecutor = NetworkServiceRefreshTokenActionOnceExecutor() } }
    private let apiProvider: MoyaProvider<Target>
    private let tokenRefreshProvider: MUNKTokenProvider
    private var tokenRefresher: NetworkServiceTokenRefresher { NetworkServiceTokenRefresher(tokenRefreshProvider: tokenRefreshProvider) }
    private var onceExecutor: NetworkServiceRefreshTokenActionOnceExecutor?

    public init(apiProvider: MoyaProvider<Target>, tokenRefreshProvider: MUNKTokenProvider) {
        self.apiProvider = apiProvider
        self.tokenRefreshProvider = tokenRefreshProvider
    }

    public func request<T: Decodable & Sendable>(target: Target) async throws -> T {
        print("NetworkService. Request \(target) started")

        do {
            return try await performRequest(target: target)
        } catch {
            try _Concurrency.Task.checkCancellation()

            if target.isRefreshTokenRequest == false,
               let serverError = error as? MoyaError,
               serverError.errorCode == 403
            {
                try await refreshToken()

                print("NetworkService. Request \(target) started")

                return try await performRequest(target: target)
            } else {
                print("NetworkService. Request \(target) failed with error \(error)")

                throw error
            }
        }
    }

    public func request(target: Target) async throws {
        print("NetworkService. Request \(target) started")

        do {
            return try await performRequest(target: target)
        } catch {
            try _Concurrency.Task.checkCancellation()

            if target.isRefreshTokenRequest == false,
               let serverError = error as? MoyaError,
               serverError.errorCode == 403
            {
                try await refreshToken()

                print("NetworkService. Request \(target) started")

                return try await performRequest(target: target)
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

    private func performRequest<T: Decodable & Sendable>(target: Target) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            apiProvider.request(target) { [weak self] result in
                switch result {
                case .success(let response):
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
