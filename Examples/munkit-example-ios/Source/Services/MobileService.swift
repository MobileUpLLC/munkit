//
//  MobileService.swift
//  exampleApp
//
//  Created by Natalia Luzyanina on 18.04.2025.
//

import Foundation
import Moya
import munkit
import munkit_example_core

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
