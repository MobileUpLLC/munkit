//
//  main.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit
import munkit_example_core
import Foundation

let tokenProvider = TokenProvider()

let networkService = await getNetworkService(
    plugins: [],
    tokenRefreshProvider: tokenProvider,
    tokenRefreshFailureHandler: { print("🧨 Token refresh failed handler called") }
)

let repository = await DNDClassesRepository(networkService: networkService)

let observer1 = await Observer(name: "observer1", replica: repository.replica)
let observer2 = await Observer(name: "observer2", replica: repository.replica)

Task {
    try await _Concurrency.Task.sleep(for: .seconds(5))
    await observer1.simulateActivity()
}

Task {
    try await _Concurrency.Task.sleep(for: .seconds(5))
    await observer2.simulateActivity()
}


try await _Concurrency.Task.sleep(for: .seconds(10))
let observer3 = await Observer(name: "observer3", replica: repository.replica)

try await _Concurrency.Task.sleep(for: .seconds(120))
