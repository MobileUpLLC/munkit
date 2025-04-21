//
//  KeyedReplicaObserver.swift
//  munkit
//
//  Created by Natalia Luzyanina on 16.04.2025.
//

import Foundation

public actor KeyedReplicaObserver<T: Sendable, K: Hashable & Sendable>: ReplicaObserver {
    public let stateStream: AsyncStream<ReplicaState<T>>
    private let eventStream: AsyncStream<ReplicaEvent<T>>

    private let activityStream: AsyncStream<Bool>
    private let keyStream: AsyncStream<K?>
    private let replicaProvider: (K) async -> (any PhysicalReplica<T>)?

    private var currentReplica: (any PhysicalReplica<T>)?
    private var currentReplicaObserver: (any ReplicaObserver<T>)?
    private var stateObservingTask: Task<Void, Never>?
    private var errorObservingTask: Task<Void, Never>?

    private let stateContinuation: AsyncStream<ReplicaState<T>>.Continuation
    private let eventContinuation: AsyncStream<ReplicaEvent<T>>.Continuation

    public init(
        activityStream: AsyncStream<Bool>,
        keyStream: AsyncStream<K?>,
        replicaProvider: @escaping (K) async -> (any PhysicalReplica<T>)?
    ) {
        self.activityStream = activityStream
        self.keyStream = keyStream
        self.replicaProvider = replicaProvider

        let (stateStream, stateContinuation) = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.stateStream = stateStream
        self.stateContinuation = stateContinuation
   //     stateContinuation.yield(ReplicaState<T>())

        let (eventStream, eventContinuation) = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.eventStream = eventStream
        self.eventContinuation = eventContinuation

        Task {
            await launchObserving()
        }
    }

    public func stopObserving() async {
        await cancelCurrentObserving()
    }

    private func launchObserving() async {
        for await currentKey in keyStream {
            await cancelCurrentObserving()
            await launchObservingForKey(currentKey: currentKey)
        }
    }

    private func launchObservingForKey(currentKey: K?) async {
        guard let key = currentKey, let replica = await replicaProvider(key) else {
            stateContinuation.yield(ReplicaState<T>.createEmpty(hasStorage: false))
            return
        }

        currentReplica = replica
        currentReplicaObserver = await replica.observe(activityStream: activityStream)

        guard let observer = currentReplicaObserver else {
            stateContinuation.yield(ReplicaState<T>.createEmpty(hasStorage: false))
            return
        }

        stateObservingTask = Task {
            for await state in await observer.stateStream {
                stateContinuation.yield(state)
            }
        }
        // TODO: 
//        errorObservingTask = Task {
//            for await event in observer.eventStream {
//                if case .loading(.error(let error)) = event {
//                    eventContinuation.yield(event)
//                }
//            }
//        }
    }

    private func cancelCurrentObserving() async {
        currentReplica = nil
        await currentReplicaObserver?.stopObserving()
        currentReplicaObserver = nil

        stateObservingTask?.cancel()
        stateObservingTask = nil

        errorObservingTask?.cancel()
        errorObservingTask = nil
    }
}
