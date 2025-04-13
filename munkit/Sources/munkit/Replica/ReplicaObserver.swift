//
//  ReplicaObserver.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

public actor ReplicaObserver<T> where T: Sendable {
    public let replicaStateStream: AsyncStream<ReplicaState<T>>
    private var replicaStateObservingTask: Task<Void, Never>?

    private let observerActive: AsyncStream<Bool>
    private var observerControllingTask: Task<Void, Never>?
    private let observersController: ReplicaObserversController<T>

    init(
        observerActive: AsyncStream<Bool>,
        replicaStateStream: AsyncStream<ReplicaState<T>>,
        externalEventStream: AsyncStream<ReplicaEvent<T>>,
        observersController: ReplicaObserversController<T>
    ) async {
        self.observerActive = observerActive
        self.observersController = observersController
        self.replicaStateStream = replicaStateStream

        await launchObserverControlling()
    }

    public func cancelObserving() async {
        observerControllingTask?.cancel()
        observerControllingTask = nil

        replicaStateObservingTask?.cancel()
        replicaStateObservingTask = nil
    }

    /// отслеживает активность наблюдателя
    private func launchObserverControlling() async {
        let observerId = UUID()

        await observersController.onObserverAdded(observerId: observerId, isObserverActive: true)

        observerControllingTask = Task {
            for await active in observerActive {
                if active {
                    await observersController.onObserverActive(observerId: observerId)
                } else {
                    await observersController.onObserverInactive(observerId: observerId)
                }
            }

            await observersController.onObserverRemoved(observerId: observerId)
        }
    }
}
