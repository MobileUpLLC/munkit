//
//  ReplicaClearingController.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 10.04.2025.
//

import Foundation

actor ReplicaClearingController<T> where T: Sendable {
    private let replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation
    private let storage: (any Storage<T>)?

    init(
        replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation,
        storage: (any Storage<T>)?
    ) {
        self.replicaEventStreamContinuation = replicaEventStreamContinuation
        self.storage = storage
    }

    func updateState(_ newState: ReplicaState<T>) async {}

    func clear(removeFromStorage: Bool) async throws {
        replicaEventStreamContinuation.yield(.cleared)

        if removeFromStorage {
            try await storage?.remove()
        }
    }

    func clearError() async {
        replicaEventStreamContinuation.yield(.clearedError)
    }
}
