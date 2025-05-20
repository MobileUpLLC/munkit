//
//  Observer.swift
//  munkit-example-clt
//
//  Created by Ilia Chub on 16.04.2025.
//

import munkit
import munkit_example_core

actor Observer: Sendable {
    private let name: String
    private let replica: any SingleReplica<DNDClassesListModel>
    private let observer: ReplicaObserver<DNDClassesListModel>
    let activityStream: AsyncStreamBundle<Bool>
    private var observingStateTask: Task<Void, Never>?

    init(name: String, replica: any SingleReplica<DNDClassesListModel>) async {
        self.name = name
        self.replica = replica
        self.activityStream = AsyncStream<Bool>.makeStream()
        self.observer = await replica.observe(activityStream: activityStream.stream)

        self.observingStateTask = Task {
            for await state in await observer.stateStream {
                await handleNewState(state)
            }
        }
    }

    deinit {
        print("🗑️", name, #function)
    }

    func stopObserving() async {
        observingStateTask?.cancel()
        observingStateTask = nil
        activityStream.continuation.finish()
    }

    private func handleNewState(_ state: ReplicaState<DNDClassesListModel>) async {
//        print("🤖", name, #function, state)
    }
}
