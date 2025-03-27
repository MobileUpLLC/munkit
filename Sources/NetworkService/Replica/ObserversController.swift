import Foundation

protocol TimeProvider {
    var currentTime: Date { get }
}

actor ObserversController<T> {
    /// Провайдер времени для отметки событий
    private let timeProvider: TimeProvider
    /// Текущее состояние реплики
    private var replicaState: ReplicaState<T>

    /// Поток событий реплики для уведомления о изменениях.
  //  private var replicaEventFlow: AsyncStream<ReplicaEvent<T>>
    
    /// Объект для управления потоком событий.
    private var eventContinuation: AsyncStream<ReplicaEvent<T>>.Continuation?

    // Предоставляем доступ к состоянию через метод
    func currentState() -> ReplicaState<T> {
        replicaState
    }

    init(timeProvider: TimeProvider, initialState: ReplicaState<T>) {
        self.timeProvider = timeProvider
        self.replicaState = initialState
    }

    /// Обрабатывает добавление нового наблюдателя.
    func onObserverAdded(observerId: UUID, active: Bool) {
        let state = replicaState
        let observingState = state.observingState
        
        let newActiveObserverIds = active
        ? observingState.activeObserverIds.union([observerId])
        : observingState.activeObserverIds

        let newObservingTime = active ? .now : observingState.observingTime

        replicaState.observingState = ObservingState(
            observerIds: observingState.observerIds.union([observerId]),
            activeObserverIds: newActiveObserverIds,
            observingTime: newObservingTime
        )
        
        emitObserverCountChangedEventIfRequired(
            previousObservingState: observingState,
            newObservingState: replicaState.observingState
        )
    }

    /// Обрабатывает удаление наблюдателя.
    func onObserverRemoved(observerId: UUID) {
        let state = replicaState
        let observingState = state.observingState
        
        let isLastActiveObserver = observingState.activeObserverIds.count == 1
        && observingState.activeObserverIds.contains(observerId)

        let newObservingTime = isLastActiveObserver ? .timeInPast(timeProvider.currentTime) : observingState.observingTime

        replicaState.observingState = ObservingState(
            observerIds: observingState.observerIds.subtracting([observerId]),
            activeObserverIds: observingState.activeObserverIds.subtracting([observerId]),
            observingTime: newObservingTime
        )

        emitObserverCountChangedEventIfRequired(
            previousObservingState: observingState,
            newObservingState: replicaState.observingState
        )
    }

    /// Обрабатывает активацию существующего наблюдателя.
    func onObserverActive(observerId: UUID) {
        let state = replicaState
        let observingState = state.observingState

        var newActiveObserverIds = observingState.activeObserverIds
        newActiveObserverIds.insert(observerId)

        replicaState.observingState = ObservingState(
            observerIds: observingState.observerIds,
            activeObserverIds: newActiveObserverIds,
            observingTime: .now
        )

        emitObserverCountChangedEventIfRequired(
            previousObservingState: observingState,
            newObservingState: replicaState.observingState
        )
    }

    /// Обрабатывает деактивацию наблюдателя.
    func onObserverInactive(observerId: UUID) {
        let state = replicaState
        let observingState = state.observingState
        
        let lastActiveObserver = observingState.activeObserverIds.count == 1
        && observingState.activeObserverIds.contains(observerId)

        let newObservingTime = lastActiveObserver ? .timeInPast(timeProvider.currentTime) : observingState.observingTime

        replicaState.observingState = ObservingState(
            observerIds: observingState.observerIds,
            activeObserverIds: observingState.activeObserverIds.subtracting([observerId]),
            observingTime: newObservingTime
        )

        emitObserverCountChangedEventIfRequired(
            previousObservingState: observingState,
            newObservingState: replicaState.observingState
        )
    }

    /// Генерирует событие об изменении количества наблюдателей, если оно изменилось.
    private func emitObserverCountChangedEventIfRequired(
        previousObservingState: ObservingState,
        newObservingState: ObservingState
    ) {
        if previousObservingState.observerCount != newObservingState.observerCount ||
           previousObservingState.activeObserverCount != newObservingState.activeObserverCount {
            eventContinuation?.yield(
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
}
