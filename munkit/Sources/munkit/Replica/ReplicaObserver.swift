//
//  ReplicaObserver.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

public actor ReplicaObserver<T> where T: Sendable {
    public let stateStream: AsyncStream<ReplicaState<T>>

    private let activityStream: AsyncStream<Bool>
    private let observersController: ReplicaObserversController<T>

    init(
        activityStream: AsyncStream<Bool>,
        stateStream: AsyncStream<ReplicaState<T>>,
        eventStream: AsyncStream<ReplicaEvent<T>>,
        observersController: ReplicaObserversController<T>
    ) async {
        self.activityStream = activityStream
        self.observersController = observersController
        self.stateStream = stateStream

        await startObserverControl()
    }

    /// Monitors the observer's activity state.
    private func startObserverControl() async {
        let observerId = UUID()

        await observersController.handleObserverAdded(observerId: observerId, isActive: true)

        Task {
            for await isActive in activityStream {
                if isActive {
                    await observersController.handleObserverActivated(observerId: observerId)
                } else {
                    await observersController.handleObserverDeactivated(observerId: observerId)
                }
            }

            await observersController.handleObserverRemoved(observerId: observerId)
        }
    }
}
