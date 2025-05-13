//
//  KeyedReplicaObserver.swift
//  munkit
//
//  Created by Ilia Chub on 13.05.2025.
//

import Foundation

public actor KeyedReplicaObserver<K: Sendable & Hashable, T: Sendable> {
    public let stateStream: AsyncStream<ReplicaState<T>>

    private let stateStreamContinuation: AsyncStream<ReplicaState<T>>.Continuation
    private let keyStream: AsyncStream<K>
    private let replicaProvider: (K) async -> any SingleReplica<T>

    private let activityStream: AsyncStream<Bool>
    private var currentActivity: Bool = false

    private var childActivityStreams: [AsyncStream<Bool>.Continuation] = []

    private var replicaObservingTask: Task<Void, Never>?

    init(
        activityStream: AsyncStream<Bool>,
        keyStream: AsyncStream<K>,
        replicaProvider: @escaping (K) async -> any SingleReplica<T>
    ) {
        (self.stateStream, self.stateStreamContinuation) = AsyncStream<ReplicaState<T>>.makeStream()

        self.keyStream = keyStream
        self.replicaProvider = replicaProvider
        self.activityStream = activityStream

        Task {
            for await activity in activityStream {
                await updateCurrentActivity(activity)
                await childActivityStreams.forEach { $0.yield(activity) }
            }
        }

        Task { await startKeyObserving() }
    }

    private func updateCurrentActivity(_ newValue: Bool) {
        currentActivity = newValue
    }

    private func startKeyObserving() async {
        for await key in keyStream {
            replicaObservingTask?.cancel()
            replicaObservingTask = Task {
                let internalActivityStreamBundle = AsyncStream<Bool>.makeStream()
                childActivityStreams.append(internalActivityStreamBundle.continuation)

                let observer = await replicaProvider(key).observe(activityStream: internalActivityStreamBundle.stream)
                internalActivityStreamBundle.continuation.yield(currentActivity)

                for await state in observer.stateStream {
                    stateStreamContinuation.yield(state)
                }
            }
        }
    }
}
