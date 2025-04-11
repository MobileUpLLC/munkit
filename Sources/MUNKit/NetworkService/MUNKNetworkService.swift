//
//  MUNKNetworkService.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Moya
import Foundation

public actor MUNKNetworkService<Target: MUNKMobileApiTargetType> {
    private var onTokenRefreshFailed: (() -> Void)?
    private let apiProvider: MoyaProvider<Target>
    private let tokenRefresher: NetworkServiceTokenRefresher
    private let unauthorizedStatusCodes: Set<Int> = [401, 403, 409]

    public init(apiProvider: MoyaProvider<Target>, tokenRefreshProvider: MUNKTokenProvider) {
        self.apiProvider = apiProvider
        self.tokenRefresher = NetworkServiceTokenRefresher(tokenRefreshProvider: tokenRefreshProvider)
    }

    public func setTokenRefreshFailedAction(_ action: @escaping () -> Void) {
        onTokenRefreshFailed = action
    }

    public func request<T: Decodable & Sendable>(target: Target, afterTockenRefreshed: Bool = false) async throws -> T {
        print("🕸️ Request \(target). Starting with expected response type: \(T.self).")

        switch await performRequest(target: target) {
        case .success(let response):
            let filteredResponse = try response.filterSuccessfulStatusCodes()
            let result = try filteredResponse.map(T.self)
            print("🕸️ Request \(target). Completed successfully.")
            return result
        case .failure(let error):
            try await handleRequestError(error, target: target, afterTockenRefreshed: afterTockenRefreshed)
            return try await request(target: target, afterTockenRefreshed: true)
        }
    }

    public func request(target: Target, afterTockenRefreshed: Bool = false) async throws {
        print("🕸️ Request \(target). Starting.")

        switch await performRequest(target: target) {
        case .success(let response):
            let _ = try response.filterSuccessfulStatusCodes()
            print("🕸️ Request \(target). Completed successfully.")
        case .failure(let error):
            try await handleRequestError(error, target: target, afterTockenRefreshed: afterTockenRefreshed)
            try await request(target: target, afterTockenRefreshed: true)
        }
    }

    private func handleRequestError(
        _ error: MoyaError,
        target: Target,
        afterTockenRefreshed: Bool
    ) async throws {
        print("🕸️ Request \(target). Failed with error: \(error.localizedDescription)")

        guard afterTockenRefreshed == false else {
            print("🕸️ Request \(target). Too many attempts to refresh token.")
            throw error
        }

        try await updateTokenIfNeeded(error, target: target)
    }

    private func performRequest(target: Target) async -> Result<Response, MoyaError> {
        return await withCheckedContinuation { continuation in
            apiProvider.request(target) { continuation.resume(returning: $0) }
        }
    }

    private func updateTokenIfNeeded(_ error: Error, target: Target) async throws {
        print("🕸️ Request \(target). Checking if token refresh is needed.")

        guard
            let serverError = error as? MoyaError,
            let statusCode = serverError.response?.statusCode,
            unauthorizedStatusCodes.contains(statusCode)
        else {
            print("🕸️ Request \(target). Failed without token refresh. Error: \(error.localizedDescription).")
            throw error
        }

        if target.isAccessTokenRequired {
            try await refreshToken(target: target)
        } else {
            throw error
        }
    }

    private func refreshToken(target: Target) async throws {
        print("🕸️ Request \(target). Initiating token refresh.")

        do {
            try await tokenRefresher.refreshToken()
            print("🕸️ Request \(target). Token refreshed successfully.")
        } catch {
            print("🕸️ Request \(target). Token refresh failed with error: \(error.localizedDescription).")

            onTokenRefreshFailed?()
            onTokenRefreshFailed = nil

            throw error
        }
    }
}
