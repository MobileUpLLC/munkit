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
    private let replica: PhysicalReplicaImplementation<T>

    init(
        activityStream: AsyncStream<Bool>,
        stateStream: AsyncStream<ReplicaState<T>>,
        replica: PhysicalReplicaImplementation<T>
    ) async {
        self.activityStream = activityStream
        self.replica = replica
        self.stateStream = stateStream

        await startObserverControl()
    }

    /// Monitors the observer's activity state.
    private func startObserverControl() async {
        let observerId = UUID()

        await replica.handleObserverAdded(observerId: observerId, isActive: true)

        Task {
            for await isActive in activityStream {
                if isActive {
                    await replica.handleObserverActivated(observerId: observerId)
                } else {
                    await replica.handleObserverDeactivated(observerId: observerId)
                }
            }

            await replica.handleObserverRemoved(observerId: observerId)
        }
    }
}
