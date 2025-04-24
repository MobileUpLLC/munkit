//
//  main.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 11.04.2025.
//

import munkit
<<<<<<< HEAD
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
=======
import Moya
import Foundation

private let accessTokenProviderAndRefresher = AccessTokenProviderAndRefresher()

private let networkService = MUNNetworkService<DNDAPITarget>(plugins: [MockAuthPlugin()])
await networkService.setAuthorizationObjects(
    provider: accessTokenProviderAndRefresher,
    refresher: accessTokenProviderAndRefresher,
    tokenRefreshFailureHandler: { print("🧨 Token refresh failed handler called") }
)

let dndClassesRepository = await DNDClassesRepository(networkService: networkService)

var completedTasks = 0
let taskCount = 30

await withTaskGroup { group in
    for id in 1...taskCount {
        group.addTask {
            print("👁️🔑", #function, "\(id)")
            do {
                let _ = try await dndClassesRepository.getClassesListWithAuth()
                print("🥳🔑", #function, "\(id)")
            } catch {
                print("☠️🔑", #function, "\(id)")
            }

            await MainActor.run { completedTasks += 1 }
        }

        group.addTask {
            print("👁️", #function, "\(id)")
            do {
                let _ = try await dndClassesRepository.getClassesListWithoutAuth()
                print("🥳", #function, "\(id)")
            } catch {
                print("☠️", #function, "\(id)")
            }

            await MainActor.run { completedTasks += 1 }
        }
    }
    await group.waitForAll()
}

if completedTasks != taskCount * 2 {
    print("🚨 completedTasks: \(completedTasks) != \(taskCount * 2)")
} else {
    print("✅ All tasks finished (maybe without success)!")
}
>>>>>>> main
