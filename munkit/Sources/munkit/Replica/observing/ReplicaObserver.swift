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
    private let observerDelegate: ReplicaObserverDelegate

    init(
        activityStream: AsyncStream<Bool>,
        stateStream: AsyncStream<ReplicaState<T>>,
        observerDelegate: ReplicaObserverDelegate
    ) async {
        self.activityStream = activityStream
        self.observerDelegate = observerDelegate
        self.stateStream = stateStream

        await startObserverControl()
    }

    /// Monitors the observer's activity state.
    private func startObserverControl() async {
        let observerId = UUID()

        await observerDelegate.handleObserverAdded(observerId: observerId, isActive: true)

        Task {
            for await isActive in activityStream {
                if isActive {
                    await observerDelegate.handleObserverActivated(observerId: observerId)
                } else {
                    await observerDelegate.handleObserverDeactivated(observerId: observerId)
                }
            }

            await observerDelegate.handleObserverRemoved(observerId: observerId)
        }
    }
}
