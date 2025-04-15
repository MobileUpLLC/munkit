//
//  main.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import Moya
import munkit
import munkit_example_core
import Foundation

let tokenProvider = TokenProvider(accessToken: "0")

let apiProvider = MoyaProvider<DNDAPITarget>(
    session: Session(startRequestsImmediately: true),
    plugins: [MUNLoggerPlugin.instance]
)

let networkService = await getNetworkService(
    apiProvider: apiProvider,
    tokenRefreshProvider: tokenProvider,
    setTokenRefreshFailureHandler: { print("🧨 Token refresh failed handler called") }
)

let repository = await DNDClassesRepository(networkService: networkService)

let observerActivityStream: AsyncStreamBundle = AsyncStream<Bool>.makeStream()
let observer = await repository.replica.observe(activityStream: observerActivityStream.stream)

// observerActivityStream.continuation.yield(true)
// Task.sleep(for: .seconds(2))
// observerActivityStream.continuation.yield(false)

try await _Concurrency.Task.sleep(for: .seconds(10))
