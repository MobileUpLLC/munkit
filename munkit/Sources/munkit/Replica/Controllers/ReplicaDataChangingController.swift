//
//  ReplicaDataChangingController.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 11.04.2025.
//

import Foundation

actor ReplicaDataChangingController<T> where T: Sendable {
    private var replicaState: ReplicaState<T>
    private let replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation
    private let storage: (any Storage<T>)?

    init(
        replicaState: ReplicaState<T>,
        replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation,
        storage: (any Storage<T>)?
    ) {
        self.replicaState = replicaState
        self.replicaEventStreamContinuation = replicaEventStreamContinuation
        self.storage = storage
    }

    func updateState(_ newState: ReplicaState<T>) async {
        self.replicaState = newState
    }

    func setData(data: T) async throws {
        let currentData = replicaState.data

        let updatedData = ReplicaData(
            value: data,
            isFresh: currentData?.isFresh ?? false,
            changingDate: .now,
            optimisticUpdates: currentData?.optimisticUpdates ?? []
        )

        replicaEventStreamContinuation.yield(.changing(.dataSetting(data: updatedData)))
        try await storage?.write(data: data)
    }

    func mutateData(transform: @escaping (T) -> T) async throws {
        if let currentData = replicaState.data {
            let newValue = transform(currentData.value)

            let updatedData = ReplicaData(
                value: newValue,
                isFresh: currentData.isFresh,
                changingDate: .now,
                optimisticUpdates: currentData.optimisticUpdates
            )

            try await storage?.write(data: newValue)
            replicaEventStreamContinuation.yield(.changing(.dataMutating(data: updatedData)))
        }
    }
}
