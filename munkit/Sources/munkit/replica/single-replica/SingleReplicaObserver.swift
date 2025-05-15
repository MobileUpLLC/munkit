//
//  SingleReplicaObserver.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

public actor SingleReplicaObserver<T> where T: Sendable {
    public let stateStream: AsyncStream<ReplicaState<T>>

    let observerId = UUID()
    let eventStream: AsyncStream<ReplicaObserverEvent>

    private let eventStreamContinuation: AsyncStream<ReplicaObserverEvent>.Continuation
    private let activityStream: AsyncStream<Bool>
    private var observingTask: Task<Void, Never>?

    init(activityStream: AsyncStream<Bool>, stateStream: AsyncStream<ReplicaState<T>>) async {
        self.activityStream = activityStream
        self.stateStream = stateStream

        (self.eventStream, self.eventStreamContinuation) = AsyncStream<ReplicaObserverEvent>.makeStream()

        await startObserverControl()
    }

    deinit {
        print(123)
    }

    private func startObserverControl() async {
        eventStreamContinuation.yield(.observerAdded)

        observingTask = Task {
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
