//
//  NetworkService.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Moya
import Foundation

public actor MUNNetworkService<Target: MUNAPITarget> {
    private let moyaProvider: MoyaProvider<Target>

    private let tokenProvider: MUNAccessTokenProvider
    private var tokenRefreshFailureHandler: (() async -> Void)?
    private var tokenRefreshTask: _Concurrency.Task<Void, Error>?
    private let authErrorStatusCodes: Set<Int> = [401, 403, 409]

    public init(apiProvider: MoyaProvider<Target>, tokenRefreshProvider: MUNAccessTokenProvider) {
        self.moyaProvider = apiProvider
        self.tokenProvider = tokenRefreshProvider
    }

    public func setTokenRefreshFailureHandler(_ action: @escaping () async -> Void) {
        tokenRefreshFailureHandler = action
    }

    private var activeRequests: Set<UUID> = []
    private var requestsPendingTokenRefresh: Set<UUID> = []

    public func executeRequest<T: Decodable & Sendable>(
        target: Target,
        isTokenRefreshed: Bool = false
    ) async throws -> T {
        let requestId = UUID()
        activeRequests.insert(requestId)
        let result = await performRequest(target: target)

        switch result {
        case .success(let response):
            let filteredResponse = try response.filterSuccessfulStatusCodes()
            let result = try filteredResponse.map(T.self)
            activeRequests.remove(requestId)
            requestsPendingTokenRefresh.remove(requestId)
            return result
        case .failure(let error):
            do {
                try await resolveRequestError(
                    error,
                    requestId: requestId,
                    target: target,
                    isTokenRefreshed: isTokenRefreshed
                )
            } catch {
                activeRequests.remove(requestId)
                requestsPendingTokenRefresh.remove(requestId)
            }
            return try await executeRequest(target: target, isTokenRefreshed: true)
        }
    }

    public func executeRequest(target: Target, isTokenRefreshed: Bool = false) async throws {
        let requestId = UUID()
        activeRequests.insert(requestId)
        switch await performRequest(target: target) {
        case .success(let response):
            let _ = try response.filterSuccessfulStatusCodes()
            activeRequests.remove(requestId)
            requestsPendingTokenRefresh.remove(requestId)
        case .failure(let error):
            do {
                try await resolveRequestError(
                    error,
                    requestId: requestId,
                    target: target,
                    isTokenRefreshed: isTokenRefreshed
                )
            } catch {
                activeRequests.remove(requestId)
                requestsPendingTokenRefresh.remove(requestId)
            }
            try await executeRequest(target: target, isTokenRefreshed: true)
        }
    }

    private func resolveRequestError(
        _ error: MoyaError,
        requestId: UUID,
        target: Target,
        isTokenRefreshed: Bool
    ) async throws {
        guard
            target.isAccessTokenRequired,
            isTokenRefreshed == false,
            let serverError = error as? MoyaError,
            let statusCode = serverError.response?.statusCode,
            authErrorStatusCodes.contains(statusCode)
        else {
            throw error
        }

        if let tokenRefreshTask {
            return try await tokenRefreshTask.value
        }

        if requestsPendingTokenRefresh.contains(requestId) {
            return
        }

        requestsPendingTokenRefresh = activeRequests
        tokenRefreshTask = _Concurrency.Task { [weak self] in
            try await self?.tokenProvider.refreshToken()
        }

        do {
            try await tokenRefreshTask?.value
            tokenRefreshTask = nil
        } catch {
            await tokenRefreshFailureHandler?()
            tokenRefreshFailureHandler = nil
            throw error
        }
    }

    private func performRequest(target: Target) async -> Result<Response, MoyaError> {
        return await withCheckedContinuation { continuation in
            moyaProvider.request(target) { continuation.resume(returning: $0) }
        }
    }
}
