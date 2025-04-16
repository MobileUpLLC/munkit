//
//  KeyedReplicaObserversController.swift
//  munkit
//
//  Created by Natalia Luzyanina on 16.04.2025.
//

import Foundation

actor KeyedReplicaObserversController<K: Hashable & Sendable, T: Sendable> {
    private var keyedReplicaState: KeyedReplicaState
    private let eventStreamContinuation: AsyncStream<KeyedReplicaEvent<K, T>>.Continuation

    public init(
        initialState: KeyedReplicaState,
        eventStreamContinuation: AsyncStream<KeyedReplicaEvent<K, T>>.Continuation
    ) {
        self.keyedReplicaState = initialState
        self.eventStreamContinuation = eventStreamContinuation
    }

    func updateState(_ newState: KeyedReplicaState) async {
        self.keyedReplicaState = newState
    }

    public func setupObserverCounting(replica: any PhysicalReplica<T>) async {
        // TODO 
        for await event in await replica.observersControllerEventStream.stream {
            if case .observerCountChanged(let observingState) = event {

                let previousCount = observingState.observersCountInfo.previousCount
                let count = observingState.observersCountInfo.count
                let previousActiveCount = observingState.observersCountInfo.previousActiveCount
                let activeCount = observingState.observersCountInfo.activeCount

                let replicaWithObserversCountDiff = {
                    if count > 0 && previousCount == 0 { return 1 }
                    if count == 0 && previousCount > 0 { return -1 }
                    return 0
                }()

                let replicaWithActiveObserversCountDiff = {
                    if activeCount > 0 && previousActiveCount == 0 { return 1 }
                    if activeCount == 0 && previousActiveCount > 0 { return -1 }
                    return 0
                }()

                if replicaWithObserversCountDiff != 0 || replicaWithActiveObserversCountDiff != 0 {
                    let currentState = keyedReplicaState

//                    let newState = KeyedReplicaState(
//                        replicaCount: currentState.replicaCount,
//                        replicaWithObserversCount: currentState.replicaWithObserversCount + replicaWithObserversCountDiff,
//                        replicaWithActiveObserversCount: currentState.replicaWithActiveObserversCount + replicaWithActiveObserversCountDiff
//                    )
                    let replicaWithObserversCount = currentState.replicaWithObserversCount + replicaWithObserversCountDiff
                    let replicaWithActiveObserversCount = currentState.replicaWithActiveObserversCount + replicaWithActiveObserversCountDiff

                    // TODO: 
                    // в оригинальной реплике нет этого события, подумать
                    eventStreamContinuation.yield(
                        .replicaObserverCountChanged(
                            replicaWithObserversCount: replicaWithObserversCount,
                            replicaWithActiveObserversCount: replicaWithActiveObserversCount
                        )
                    )
                }
            }
        }
    }
}
