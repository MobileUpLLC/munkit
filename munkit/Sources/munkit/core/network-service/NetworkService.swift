//
//  MUNNetworkService.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Moya
import Foundation

public actor MUNNetworkService<Target: MUNAPITarget> {
    private var moyaProvider: MoyaProvider<Target>
    private var accessTokenRefresher: MUNAccessTokenRefresher?

    private var tokenRefreshFailureHandler: (() async -> Void)?
    private var tokenRefreshTask: _Concurrency.Task<Void, Error>?
    private var activeRequests: Set<NetworkServiceActiveRequest> = []
    private var requestsPendingTokenRefresh: Set<UUID> = []

    public init(
        session: Session = MoyaProvider<Target>.defaultAlamofireSession(),
        plugins: [any PluginType] = [],
    ) {
        self.moyaProvider = MoyaProvider<Target>.init(
            stubClosure: { $0.isMockEnabled ? .delayed(seconds: 1.5) : .never },
            session: session,
            plugins: plugins
        )
    }

    public func setAuthorizationObjects(
        provider: MUNAccessTokenProvider,
        refresher: MUNAccessTokenRefresher,
        tokenRefreshFailureHandler: @escaping () async -> Void
    ) {
        self.accessTokenRefresher = refresher
        self.tokenRefreshFailureHandler = tokenRefreshFailureHandler

        let accessTokenPlugin = AccessTokenPlugin(accessTokenProvider: provider)
        self.moyaProvider = MoyaProvider<Target>(
            stubClosure: moyaProvider.stubClosure,
            session: moyaProvider.session,
            plugins: moyaProvider.plugins + [accessTokenPlugin]
        )
    }

    public func executeRequest<T: Decodable & Sendable>(
        target: Target,
        isTokenRefreshed: Bool = false
    ) async throws -> T {
        throw MoyaError.requestMapping("Not implemented")
        let requestId = startRequest(isAccessTokenRequired: target.isAccessTokenRequired)
        defer { completeRequest(requestId) }

        switch try await performRequest(target: target) {
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
        let requestId = startRequest(isAccessTokenRequired: target.isAccessTokenRequired)
        defer { completeRequest(requestId) }

        switch try await performRequest(target: target) {
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

    private func startRequest(isAccessTokenRequired: Bool) -> UUID {
        let requestId = UUID()
        activeRequests.insert(
            NetworkServiceActiveRequest(id: requestId, isAccessTokenRequired: isAccessTokenRequired)
        )
        return requestId
    }

    private func performRequest(target: Target) async throws -> Result<Response, MoyaError> {
        try await _Concurrency.Task.checkCancellation()
        let result = await withCheckedContinuation { continuation in
            moyaProvider.request(target) { continuation.resume(returning: $0) }
        }
        try await _Concurrency.Task.checkCancellation()
        return result
    }

    private func completeRequest(_ requestId: UUID) {
        if let index = activeRequests.firstIndex(where: { $0.id == requestId }) {
            activeRequests.remove(at: index)
        }
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
            target.isRefreshTokenRequest == false,
            isTokenRefreshed == false,
            let statusCode = error.response?.statusCode,
            [401, 403, 409].contains(statusCode)
        else {
            throw error
        }

        if let tokenRefreshTask {
            return try await tokenRefreshTask.value
        } else if requestsPendingTokenRefresh.contains(requestId) {
            return
        }

        requestsPendingTokenRefresh = Set(activeRequests.compactMap { $0.isAccessTokenRequired ? $0.id : nil })
        tokenRefreshTask = _Concurrency.Task { [weak self] in
            guard let accessTokenRefresher = await self?.accessTokenRefresher else {
                throw error
            }

            try await accessTokenRefresher.refresh()
        }

        do {
            try await tokenRefreshTask?.value
            tokenRefreshTask = nil
        } catch {
            await tokenRefreshFailureHandler?()
            throw error
        }
    }
}
