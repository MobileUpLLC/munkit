//
//  ReplicaObserver.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

public actor ReplicaObserver<T> where T: Sendable {
    public let observerId = UUID()
    public let stateStream: AsyncStream<ReplicaState<T>>

    let eventStream: AsyncStream<ReplicaObserverEvent>

    private let eventStreamContinuation: AsyncStream<ReplicaObserverEvent>.Continuation
    private let activityStream: AsyncStream<Bool>

    init(
        activityStream: AsyncStream<Bool>,
        stateStream: AsyncStream<ReplicaState<T>>
    ) async {
        self.activityStream = activityStream
        self.stateStream = stateStream

        (self.eventStream, self.eventStreamContinuation) = AsyncStream<ReplicaObserverEvent>.makeStream()

        await startObserverControl()
    }

    /// Monitors the observer's activity state.
    private func startObserverControl() async {
        await eventStreamContinuation.yield(.observerAdded)

        Task {
            for await isActive in activityStream {
                print(observerId, "isActive:", isActive)
                if isActive {
                    await eventStreamContinuation.yield(.observerActivated)
                } else {
                    await eventStreamContinuation.yield(.observerDeactivated)
                }
            }

            await eventStreamContinuation.yield(.observerRemoved)
        }
    }
}
