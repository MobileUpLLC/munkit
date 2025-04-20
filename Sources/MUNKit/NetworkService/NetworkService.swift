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
    private var activeRequests: Set<UUID> = []
    private var requestsPendingTokenRefresh: Set<UUID> = []

    public init(apiProvider: MoyaProvider<Target>, tokenRefreshProvider: MUNAccessTokenProvider) {
        self.moyaProvider = apiProvider
        self.tokenProvider = tokenRefreshProvider
    }

    public func setTokenRefreshFailureHandler(_ action: @escaping () async -> Void) {
        tokenRefreshFailureHandler = action
    }

    public func executeRequest<T: Decodable & Sendable>(
        target: Target,
        isTokenRefreshed: Bool = false
    ) async throws -> T {
        let requestId = startRequest()
        defer { completeRequest(requestId) }

        switch await performRequest(target: target) {
        case .success(let response):
            let filteredResponse = try response.filterSuccessfulStatusCodes()
            return try filteredResponse.map(T.self)
        case .failure(let error):
            try await resolveRequestError(
                error,
                requestId: requestId,
                target: target,
                isTokenRefreshed: isTokenRefreshed
            )
            return try await executeRequest(target: target, isTokenRefreshed: true)
        }
    }

    public func executeRequest(target: Target, isTokenRefreshed: Bool = false) async throws {
        let requestId = startRequest()
        defer { completeRequest(requestId) }

        switch await performRequest(target: target) {
        case .success(let response):
            let _ = try response.filterSuccessfulStatusCodes()
        case .failure(let error):
            try await resolveRequestError(
                error,
                requestId: requestId,
                target: target,
                isTokenRefreshed: isTokenRefreshed
            )
            try await executeRequest(target: target, isTokenRefreshed: true)
        }
    }

    private func startRequest() -> UUID {
        let requestId = UUID()
        activeRequests.insert(requestId)
        return requestId
    }

    private func performRequest(target: Target) async -> Result<Response, MoyaError> {
        return await withCheckedContinuation { continuation in
            moyaProvider.request(target) { continuation.resume(returning: $0) }
        }
    }

    private func completeRequest(_ requestId: UUID) {
        activeRequests.remove(requestId)
        requestsPendingTokenRefresh.remove(requestId)
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
            [401, 403, 409].contains(statusCode)
        else {
            throw error
        }

        if let tokenRefreshTask {
            return try await tokenRefreshTask.value
        } else if requestsPendingTokenRefresh.contains(requestId) {
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
}
