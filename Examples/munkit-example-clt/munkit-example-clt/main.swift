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

let firstObserverActivityStream: AsyncStreamBundle = AsyncStream<Bool>.makeStream()
let secondeObserverActivityStream: AsyncStreamBundle = AsyncStream<Bool>.makeStream()

let firstObserver = await repository.replica.observe(activityStream: firstObserverActivityStream.stream)
let secondeObserver = await repository.replica.observe(activityStream: secondeObserverActivityStream.stream)

firstObserverActivityStream.continuation.yield(true)
try await _Concurrency.Task.sleep(for: .seconds(2))
secondeObserverActivityStream.continuation.yield(true)

try await _Concurrency.Task.sleep(for: .seconds(2))

firstObserverActivityStream.continuation.yield(false)
try await _Concurrency.Task.sleep(for: .seconds(2))
secondeObserverActivityStream.continuation.yield(false)


try await _Concurrency.Task.sleep(for: .seconds(10))
