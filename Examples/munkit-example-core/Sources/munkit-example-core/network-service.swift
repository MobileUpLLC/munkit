//
//  network-service.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 14.04.2025.
//

import munkit
@preconcurrency import Moya

private let tokenProvider = TokenProvider()

@MainActor private let provider = MoyaProvider<DNDAPITarget>(
    plugins: [
        MUNAccessTokenPlugin(accessTokenProvider: tokenProvider),
        MockAuthPlugin()
    ]
)

@MainActor public let networkService = MUNNetworkService(apiProvider: provider, tokenRefreshProvider: tokenProvider)

public func setupNetworkService() async {
    await networkService.setTokenRefreshFailureHandler { print("🧨 Token refresh failed handler called") }
}
