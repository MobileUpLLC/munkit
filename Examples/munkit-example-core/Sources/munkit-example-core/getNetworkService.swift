//
//  network-service.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 14.04.2025.
//

import munkit
@preconcurrency import Moya

public func getNetworkService(
    apiProvider: MoyaProvider<DNDAPITarget>,
    tokenRefreshProvider: TokenProvider,
    tokenRefreshFailureHandler: @escaping @Sendable () -> Void
) async -> MUNNetworkService<DNDAPITarget> {
    let networkService = await MUNNetworkService(apiProvider: apiProvider, tokenRefreshProvider: tokenRefreshProvider)

    await networkService.setTokenRefreshFailureHandler {
        tokenRefreshFailureHandler()
    }

    return networkService
}
