//
//  ReplicaObserver.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

public actor ReplicaObserver<T> where T: Sendable {
    public let stateStream: AsyncStream<ReplicaState<T>>

    let observerId = UUID()
    let eventStream: AsyncStream<ReplicaObserverEvent>

    private let eventStreamContinuation: AsyncStream<ReplicaObserverEvent>.Continuation
    private let activityStream: AsyncStream<Bool>

    init(activityStream: AsyncStream<Bool>, stateStream: AsyncStream<ReplicaState<T>>) async {
        self.activityStream = activityStream
        self.stateStream = stateStream

        (self.eventStream, self.eventStreamContinuation) = AsyncStream<ReplicaObserverEvent>.makeStream()

        await startObserverControl()
    }

    private func startObserverControl() async {
        eventStreamContinuation.yield(.observerAdded)

        Task {
            for await isActive in activityStream {
                if isActive {
                    eventStreamContinuation.yield(.observerActivated)
                } else {
                    eventStreamContinuation.yield(.observerDeactivated)
                }
            }

            eventStreamContinuation.yield(.observerRemoved)
        }
    }
}
