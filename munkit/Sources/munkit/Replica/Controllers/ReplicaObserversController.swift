//
//  ReplicaObserversController.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

actor ReplicaObserversController<T> where T: Sendable {
    private var replicaState: ReplicaState<T>
    private let eventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation

    init(
        initialState: ReplicaState<T>,
        eventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation
    ) {
        self.replicaState = initialState
        self.eventStreamContinuation = eventStreamContinuation
    }

    func updateState(_ newState: ReplicaState<T>) async {
        self.replicaState = newState
    }

    /// Handles the addition of a new observer.
    func handleObserverAdded(observerId: UUID, isActive: Bool) {
        let currentObservingState = replicaState.observingState

        let updatedActiveObserverIds = isActive
            ? currentObservingState.activeObserverIds.union([observerId])
            : currentObservingState.activeObserverIds

        let updatedObservingTime = isActive ? .now : currentObservingState.observingTime

        let newObservingState = ObservingState(
            observerIds: currentObservingState.observerIds.union([observerId]),
            activeObserverIds: updatedActiveObserverIds,
            observingTime: updatedObservingTime
        )

        emitStateChangeIfNeeded(
            from: currentObservingState,
            to: newObservingState
        )
    }

    /// Handles the removal of an observer.
    func handleObserverRemoved(observerId: UUID) {
        let currentObservingState = replicaState.observingState

        let isLastActive = currentObservingState.activeObserverIds.count == 1
            && currentObservingState.activeObserverIds.contains(observerId)

        let updatedObservingTime = isLastActive ? .timeInPast(.now) : currentObservingState.observingTime

        let newObservingState = ObservingState(
            observerIds: currentObservingState.observerIds.subtracting([observerId]),
            activeObserverIds: currentObservingState.activeObserverIds.subtracting([observerId]),
            observingTime: updatedObservingTime
        )

        emitStateChangeIfNeeded(
            from: currentObservingState,
            to: newObservingState
        )
    }

    /// Handles the activation of an existing observer.
    func handleObserverActivated(observerId: UUID) {
        let currentObservingState = replicaState.observingState

        var updatedActiveObserverIds = currentObservingState.activeObserverIds
        updatedActiveObserverIds.insert(observerId)

        let newObservingState = ObservingState(
            observerIds: currentObservingState.observerIds,
            activeObserverIds: updatedActiveObserverIds,
            observingTime: .now
        )

        emitStateChangeIfNeeded(
            from: currentObservingState,
            to: newObservingState
        )
    }

    /// Handles the deactivation of an observer.
    func handleObserverDeactivated(observerId: UUID) {
        let currentObservingState = replicaState.observingState

        let isLastActive = currentObservingState.activeObserverIds.count == 1
            && currentObservingState.activeObserverIds.contains(observerId)

        let updatedObservingTime = isLastActive ? .timeInPast(.now) : currentObservingState.observingTime

        let newObservingState = ObservingState(
            observerIds: currentObservingState.observerIds,
            activeObserverIds: currentObservingState.activeObserverIds.subtracting([observerId]),
            observingTime: updatedObservingTime
        )

        emitStateChangeIfNeeded(
            from: currentObservingState,
            to: newObservingState
        )
    }

    /// Emits an event if the observer state has changed.
    private func emitStateChangeIfNeeded(
        from previousState: ObservingState,
        to newState: ObservingState
    ) {
        if
            previousState.observerIds.count != newState.observerIds.count
            || previousState.activeObserverIds.count != newState.activeObserverIds.count
        {
            eventStreamContinuation.yield(.observerCountChanged(newState))
        }
    }
}
