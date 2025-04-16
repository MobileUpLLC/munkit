//
//  KeyedReplicaChildRemovingController.swift
//  munkit
//
//  Created by Natalia Luzyanina on 16.04.2025.
//

import Foundation

final class KeyedReplicaChildRemovingController<K: Hashable & Sendable, T: Sendable> {
    private let removeReplica: @Sendable (K) -> Void

    init(removeReplica: @escaping @Sendable (K) -> Void) {
        self.removeReplica = removeReplica
    }

    func setupAutoRemoving(key: K, replica: any PhysicalReplica<T>) {
        let additionalCheckTask = Task {
            try await Task.sleep(for: .seconds(0.5))

            guard Task.isCancelled == false else {
                return
            }

            if await replica.canBeRemoved {
                removeReplica(key)
            }
        }

        Task {
            for await state in replica.stateStream.dropFirst() {
                if state.canBeRemoved {
                    additionalCheckTask.cancel()
                    removeReplica(key)
                    break
                } else {
                    additionalCheckTask.cancel()
                }
            }
        }
    }
}
