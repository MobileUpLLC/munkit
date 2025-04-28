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
    private var staleTask: Task<Void, Error>?
    private let staleTime: TimeInterval

    init(
        replicaState: ReplicaState<T>,
        replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation,
        staleTime: TimeInterval
    ) {
        self.replicaState = replicaState
        self.replicaEventStreamContinuation = replicaEventStreamContinuation
        self.staleTime = staleTime
    }

    func updateState(_ newState: ReplicaState<T>) async {
        self.replicaState = newState
    }

    func invalidate() async {
        if replicaState.data?.isFresh == true {
            replicaEventStreamContinuation.yield(.freshness(.becameStale))
        }
    }

    func makeFresh() async {
        staleTask?.cancel()

        guard replicaState.data != nil else {
            return
        }

        replicaEventStreamContinuation.yield(.freshness(.freshened))

        guard staleTime < .infinity else {
            return
        }

        staleTask = Task { [weak self] in
            guard let self else { return }
            try await Task.sleep(for: .seconds(staleTime))
            replicaEventStreamContinuation.yield(.freshness(.becameStale))
        }
    }
}
