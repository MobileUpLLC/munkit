//
//  ReplicaOptimisticUpdatesController.swift
//  munkit
//
//  Created by Natalia Luzyanina on 14.04.2025.
//

import Foundation

actor ReplicaOptimisticUpdatesController<T> where T: Sendable {
    private var replicaState: ReplicaState<T>
    private let replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation
    private let storage: (any Storage<T>)?

    init(
        replicaState: ReplicaState<T>,
        replicaStateStream: AsyncStream<ReplicaState<T>>,
        replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation,
        storage: (any Storage<T>)?
    ) {
        self.replicaState = replicaState
        self.replicaEventStreamContinuation = replicaEventStreamContinuation
        self.storage = storage

        Task {
            await subscribeForReplicaStateStream(replicaStateStream: replicaStateStream)
        }
    }

    private func subscribeForReplicaStateStream(replicaStateStream: AsyncStream<ReplicaState<T>>) async {
        for await newReplicaState in replicaStateStream {
            replicaState = newReplicaState
        }
    }

    func beginOptimisticUpdate(update: any OptimisticUpdate<T>) async {
        guard let data = replicaState.data else {
            return
        }

        let updatedOptimisticUpdates = data.optimisticUpdates + [update]

        var updatedData = data
        updatedData.optimisticUpdates = updatedOptimisticUpdates

        replicaEventStreamContinuation.yield(.optimisticUpdates(.begin(data: updatedData)))
    }

    func commitOptimisticUpdate(update: any OptimisticUpdate<T>) async {
        guard let data = replicaState.data else {
            return
        }

        let newData = update.apply(to: data.value)


        let updatedOptimisticUpdates = data.optimisticUpdates.filter { $0 !== update }

        var updatedData = data
        updatedData.value = newData
        updatedData.changingDate = .now
        updatedData.optimisticUpdates = updatedOptimisticUpdates

        replicaEventStreamContinuation.yield(.optimisticUpdates(.commit(data: updatedData)))
        try? await storage?.write(data: newData)
    }

    /// Откатывает оптимистичное обновление, удаляя его из списка ожидающих обновлений.
    /// - Parameter update: Оптимистичное обновление для отката.
    func rollbackOptimisticUpdate(update: any OptimisticUpdate<T>) async {
        guard let data = replicaState.data else {
            return
        }

        let updatedOptimisticUpdates = data.optimisticUpdates.filter { $0 !== update }

        var updatedData = data
        updatedData.optimisticUpdates = updatedOptimisticUpdates

        replicaEventStreamContinuation.yield(.optimisticUpdates(.rollback(data: updatedData)))
    }
}
