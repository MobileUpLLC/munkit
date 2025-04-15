//
//  MockAuthPlugin.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit
import Moya
import Foundation

// TODO: Удалить
public actor MobileService {
    public static let shared = MobileService()

    public let networkService: MUNNetworkService<DNDAPITarget>

    private init() {
        let tokenProvider = TokenProvider()
        let configuration = URLSessionConfiguration.default
        configuration.headers = .default
        configuration.urlCache = nil

        let apiProvider = MoyaProvider<DNDAPITarget>(
            session: Session(configuration: configuration, startRequestsImmediately: true),
            plugins: [MUNLoggerPlugin.instance]
        )

        self.networkService = MUNNetworkService(apiProvider: apiProvider, tokenRefreshProvider: tokenProvider)
    }
}
