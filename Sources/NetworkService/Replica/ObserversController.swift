import Foundation

actor ObserversController<T> where T: Sendable {
    private var replicaState: ReplicaState<T>

    private let replicaStateStream: AsyncStream<ReplicaState<T>>
    private let replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation

    init(
        replicaState: ReplicaState<T>,
        replicaStateStream: AsyncStream<ReplicaState<T>>,
        replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation
    ) async {
        self.replicaState = replicaState

        self.replicaStateStream = replicaStateStream
        self.replicaEventStreamContinuation = replicaEventStreamContinuation

        launchStateObserving()
    }

    /// Обрабатывает добавление нового наблюдателя.
    func onObserverAdded(observerId: UUID, active: Bool) {
        let previousObservingState = replicaState.observingState
        
        let newActiveObserverIds = active
        ? previousObservingState.activeObserverIds.union([observerId])
        : previousObservingState.activeObserverIds

        let newObservingTime = active ? .now : previousObservingState.observingTime

        let newObservingState = ObservingState(
            observerIds: previousObservingState.observerIds.union([observerId]),
            activeObserverIds: newActiveObserverIds,
            observingTime: newObservingTime
        )
        
        yieldObservingStateIfNeeded(
            previousObservingState: previousObservingState,
            newObservingState: newObservingState
        )
    }

    /// Обрабатывает удаление наблюдателя.
    func onObserverRemoved(observerId: UUID) {
        let previousObservingState = replicaState.observingState
        
        let isLastActiveObserver = previousObservingState.activeObserverIds.count == 1
        && previousObservingState.activeObserverIds.contains(observerId)

        let newObservingTime = isLastActiveObserver ? .timeInPast(.now) : previousObservingState.observingTime

        let newObservingState = ObservingState(
            observerIds: previousObservingState.observerIds.subtracting([observerId]),
            activeObserverIds: previousObservingState.activeObserverIds.subtracting([observerId]),
            observingTime: newObservingTime
        )

        yieldObservingStateIfNeeded(
            previousObservingState: previousObservingState,
            newObservingState: newObservingState
        )
    }

    /// Обрабатывает активацию существующего наблюдателя.
    func onObserverActive(observerId: UUID) {
        let previousObservingState = replicaState.observingState

        var newActiveObserverIds = previousObservingState.activeObserverIds
        newActiveObserverIds.insert(observerId)

        let newObservingState = ObservingState(
            observerIds: previousObservingState.observerIds,
            activeObserverIds: newActiveObserverIds,
            observingTime: .now
        )

        yieldObservingStateIfNeeded(
            previousObservingState: previousObservingState,
            newObservingState: newObservingState
        )
    }

    /// Обрабатывает деактивацию наблюдателя.
    func onObserverInactive(observerId: UUID) {
        let previousObservingState = replicaState.observingState
        
        let lastActiveObserver = previousObservingState.activeObserverIds.count == 1
        && previousObservingState.activeObserverIds.contains(observerId)

        let newObservingTime = lastActiveObserver ? .timeInPast(.now) : previousObservingState.observingTime

        let newObservingState = ObservingState(
            observerIds: previousObservingState.observerIds,
            activeObserverIds: previousObservingState.activeObserverIds.subtracting([observerId]),
            observingTime: newObservingTime
        )

        yieldObservingStateIfNeeded(
            previousObservingState: previousObservingState,
            newObservingState: newObservingState
        )
    }

    /// Генерирует событие об изменении количества наблюдателей, если оно изменилось.
    private func yieldObservingStateIfNeeded(
        previousObservingState: ObservingState,
        newObservingState: ObservingState
    ) {
        if
            previousObservingState.observerCount != newObservingState.observerCount
            || previousObservingState.activeObserverCount != newObservingState.activeObserverCount
        {
            replicaEventStreamContinuation.yield(
                .observerCountChanged(
                    ObserversCountInfo(
                        count: newObservingState.observerCount,
                        activeCount: newObservingState.activeObserverCount,
                        previousCount: previousObservingState.observerCount,
                        previousActiveCount: previousObservingState.activeObserverCount
                    )
                )
            )
        }
    }

    private func launchStateObserving() {
        Task {
            for await replicaState in replicaStateStream {
                self.replicaState = replicaState
            }
        }
    }
}
