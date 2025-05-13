//
//  main.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit
import munkit_example_core
import Foundation

struct Logger: MUNLoggable {
    func logDebug(_ message: String) {
        print(message)
    }

    func logInfo(_ message: String) {
        print(message)
    }

    func logError(_ message: String) {
        print(message)
    }
}

let tokenProvider = AccessTokenProviderAndRefresher()
let networkService = MUNNetworkService<DNDAPITarget>(plugins: [MUNLoggerPlugin.instance])
MUNLogger.setupLogger(Logger())
let repository = DNDMonstersRepository(networkService: networkService)

let observer1 = await Observer(
    name: "OBSERVER_1",
    monstersListReplica: await repository.getDNDMonstersListReplica(),
    monstersReplica: await repository.getDNDMonstersReplica()
)

Task {
    try await Task.sleep(for: .seconds(1))
    await observer1.activityStreams.forEach { $0.continuation.yield(true) }
}

try await _Concurrency.Task.sleep(for: .seconds(20))
