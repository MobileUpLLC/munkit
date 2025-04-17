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
    private var hasAttemptedTokenRefresh = false

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
        switch await performRequest(target: target) {
        case .success(let response):
            let filteredResponse = try response.filterSuccessfulStatusCodes()
            let result = try filteredResponse.map(T.self)
            return result
        case .failure(let error):
            try await resolveRequestError(error, target: target, isTokenRefreshed: isTokenRefreshed)
            return try await executeRequest(target: target, isTokenRefreshed: true)
        }
    }

    public func executeRequest(target: Target, isTokenRefreshed: Bool = false) async throws {
        switch await performRequest(target: target) {
        case .success(let response):
            let _ = try response.filterSuccessfulStatusCodes()
        case .failure(let error):
            try await resolveRequestError(error, target: target, isTokenRefreshed: isTokenRefreshed)
            try await executeRequest(target: target, isTokenRefreshed: true)
        }
    }

    private func resolveRequestError(_ error: MoyaError, target: Target, isTokenRefreshed: Bool) async throws {
        guard isTokenRefreshed == false else {
            throw error
        }
        try await ensureTokenValid(error, target: target)
    }

    private func ensureTokenValid(_ error: Error, target: Target) async throws {
        guard
            let serverError = error as? MoyaError,
            let statusCode = serverError.response?.statusCode,
            authErrorStatusCodes.contains(statusCode),
            target.isAccessTokenRequired
        else {
            throw error
        }

        try await renewAccessToken(target: target)
    }

    private func renewAccessToken(target: Target) async throws {
        if let tokenRefreshTask {
            return try await tokenRefreshTask.value
        }

        guard hasAttemptedTokenRefresh == false else {
            return
        }

        hasAttemptedTokenRefresh = true
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
