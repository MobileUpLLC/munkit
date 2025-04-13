//
//  MUNKNetworkService.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Moya
import Foundation

public actor MUNKNetworkService<Target: MUNKMobileApiTargetType> {
    private var onTokenRefreshFailed: (() async -> Void)?
    private let apiProvider: MoyaProvider<Target>
    private let tokenRefreshProvider: MUNKTokenProvider
    private var refreshTokenTask: _Concurrency.Task<Void, Error>?
    private let unauthorizedStatusCodes: Set<Int> = [401, 403, 409]

    public init(apiProvider: MoyaProvider<Target>, tokenRefreshProvider: MUNKTokenProvider) {
        self.apiProvider = apiProvider
        self.tokenRefreshProvider = tokenRefreshProvider
    }

    public func setTokenRefreshFailedAction(_ action: @escaping () async -> Void) {
        onTokenRefreshFailed = action
    }

    public func request<T: Decodable & Sendable>(target: Target, afterTokenRefreshed: Bool = false) async throws -> T {
        switch await performRequest(target: target) {
        case .success(let response):
            let filteredResponse = try response.filterSuccessfulStatusCodes()
            let result = try filteredResponse.map(T.self)
            return result
        case .failure(let error):
            try await handleRequestError(error, target: target, afterTokenRefreshed: afterTokenRefreshed)
            return try await request(target: target, afterTokenRefreshed: true)
        }
    }

    public func request(target: Target, afterTokenRefreshed: Bool = false) async throws {
        switch await performRequest(target: target) {
        case .success(let response):
            let _ = try response.filterSuccessfulStatusCodes()
        case .failure(let error):
            try await handleRequestError(error, target: target, afterTokenRefreshed: afterTokenRefreshed)
            try await request(target: target, afterTokenRefreshed: true)
        }
    }

    private func handleRequestError(_ error: MoyaError, target: Target, afterTokenRefreshed: Bool) async throws {
        guard afterTokenRefreshed == false else {
            throw error
        }
        try await refreshTokenIfNeeded(error, target: target)
    }

    private func refreshTokenIfNeeded(_ error: Error, target: Target) async throws {
        guard
            let serverError = error as? MoyaError,
            let statusCode = serverError.response?.statusCode,
            unauthorizedStatusCodes.contains(statusCode)
        else {
            throw error
        }

        if target.isAccessTokenRequired {
            try await refreshToken(target: target)
        } else {
            throw error
        }
    }

    private func refreshToken(target: Target) async throws {
        if let refreshTokenTask = refreshTokenTask {
            return try await refreshTokenTask.value
        }

        refreshTokenTask = _Concurrency.Task { [weak self] in
            try await self?.tokenRefreshProvider.refreshToken()
        }

        do {
            try await refreshTokenTask?.value
            refreshTokenTask = nil
        } catch {
            await onTokenRefreshFailed?()
            onTokenRefreshFailed = nil
            throw error
        }
    }

    private func performRequest(target: Target) async -> Result<Response, MoyaError> {
        return await withCheckedContinuation { continuation in
            apiProvider.request(target) { continuation.resume(returning: $0) }
        }
    }
}
