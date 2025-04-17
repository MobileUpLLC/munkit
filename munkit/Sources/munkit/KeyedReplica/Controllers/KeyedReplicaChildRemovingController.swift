//
//  KeyedReplicaChildRemovingController.swift
//  munkit
//
//  Created by Natalia Luzyanina on 16.04.2025.
//

import Foundation

actor KeyedReplicaChildRemovingController<K: Hashable & Sendable, T: Sendable> {
    private let replicaEventStreamContinuation: AsyncStream<KeyedReplicaEvent<K, T>>.Continuation

    init(replicaEventStreamContinuation: AsyncStream<KeyedReplicaEvent<K, T>>.Continuation) {
        self.replicaEventStreamContinuation = replicaEventStreamContinuation
    }

    func setupAutoRemoving(key: K, replica: any PhysicalReplica<T>) {
        let additionalCheckTask = Task {
            try await Task.sleep(for: .seconds(0.5))

            guard Task.isCancelled == false else {
                return
            }

            if await replica.canBeRemoved {
                replicaEventStreamContinuation.yield(.replicaCanBeRemoved)
            }
        }

        // TODO: 
//        Task {
//            for await state in replica.stateStream.dropFirst() {
//                if state.canBeRemoved {
//                    additionalCheckTask.cancel()
//                    removeReplica(key)
//                    break
//                } else {
//                    additionalCheckTask.cancel()
//                }
//            }
//        }
    }
}
