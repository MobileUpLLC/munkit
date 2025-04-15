//
//  ReplicaFreshnessController.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 11.04.2025.
//

import Foundation

actor ReplicaFreshnessController<T> where T: Sendable {
    private var replicaState: ReplicaState<T>
    private let replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation

    init(
        replicaState: ReplicaState<T>,
        replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation
    ) {
        self.replicaState = replicaState
        self.replicaEventStreamContinuation = replicaEventStreamContinuation
    }

    func updateState(_ newState: ReplicaState<T>) async {
        self.replicaState = newState
    }

    func invalidate() async {
        if let data = replicaState.data, data.isFresh {
            replicaEventStreamContinuation.yield(.freshness(.becameStale))
        }
    }

    func makeFresh() async {
        if replicaState.data != nil {
            replicaEventStreamContinuation.yield(.freshness(.freshened))
        }
    }
}
