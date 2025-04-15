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

try await _Concurrency.Task.sleep(for: .seconds(10))

final class Observer: Sendable {
    private let name: String
    private let replica: any Replica<DNDClassesListModel>
    private let observer: ReplicaObserver<DNDClassesListModel>
    private let activityStream: AsyncStreamBundle<Bool>

    init(name: String, replica: any Replica<DNDClassesListModel>) async {
        self.name = name
        self.replica = replica
        self.activityStream = AsyncStream<Bool>.makeStream()
        self.observer = await replica.observe(activityStream: activityStream.stream)

        Task {
            for await state in await observer.stateStream {
                await handleNewState(state)
            }
        }

//        Task {
//            try? await Task.sleep(for: .seconds(Int.random(in: 1...3)))
//            await self.simulateActivity()
//        }
    }

    func simulateActivity() async {
        print("🤖", name, #function, "+")
        activityStream.continuation.yield(true)
        try? await Task.sleep(for: .seconds(Int.random(in: 1...5)))
        print("🤖", name, #function, "-")
        activityStream.continuation.yield(false)
        try? await Task.sleep(for: .seconds(Int.random(in: 1...5)))
        print("🤖", name, #function, "+")
        activityStream.continuation.yield(true)
    }

    private func handleNewState(_ state: ReplicaState<DNDClassesListModel>) async {
//        print("🤖", name, #function, state)
    }
}
