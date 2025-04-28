//
//  Observer.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 16.04.2025.
//

import munkit
import munkit_example_core

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
    }

    deinit {
        print("🗑️", name, #function)
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
        try? await Task.sleep(for: .seconds(Int.random(in: 1...5)))
        print("🤖", name, #function, "-")
        activityStream.continuation.yield(false)
    }

    func stopObserving() async {
        activityStream.continuation.finish()
    }

    private func handleNewState(_ state: ReplicaState<DNDClassesListModel>) async {
//        print("🤖", name, #function, state)
    }
}
