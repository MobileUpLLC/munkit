//
//  main.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit
import munkit_example_core
import Foundation

let tokenProvider = AccessTokenProviderAndRefresher()
let networkService = MUNNetworkService<DNDAPITarget>()
let repository = DNDClassesRepository(networkService: networkService)
let replica = await repository.getDNDClassesListReplica()
let observer1 = await Observer(name: "observer1", replica: replica)

Task {
    try await Task.sleep(for: .seconds(1))
    observer1.activityStream.continuation.yield(true)
}

Task {
    try await Task.sleep(for: .seconds(2))
    observer1.activityStream.continuation.yield(false)
}

try await _Concurrency.Task.sleep(for: .seconds(20))
