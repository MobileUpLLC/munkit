import Foundation

/// Наблюдатель за репликой, который подключается к реплике и получает обновления состояния и события ошибок загрузки.
public protocol ReplicaObserver<T> {
    associatedtype T
    /// Поток состояний реплики
    var replicaStateFlow: AsyncStream<ReplicaState<T>> { get }

    /// Поток событий ошибок загрузки.
    var replicaEventFlow: AsyncStream<ReplicaEvent<T>> { get }

    /// Отменяет наблюдение за репликой вручную.
    func cancelObserving() async
}

actor ReplicaObserverImpl<T> {
    /// Поток состояния реплики, получаемый от внешнего источника.
    let replicaStateFlow: AsyncStream<ReplicaState<T>>
    /// Поток событий реплики, получаемый от внешнего источника.
    let replicaEventFlow: AsyncStream<ReplicaEvent<T>>

    private let observerId: UUID
    /// Хост наблюдателя, предоставляющий область выполнения и активность.
    private let observerHost: ReplicaObserverHost

    private var observerControllingTask: _Concurrency.Task<Void, Never>?
    private var stateObservingTask: _Concurrency.Task<Void, Never>?
    private var errorsObservingTask: _Concurrency.Task<Void, Never>?

    private let observersController: ObserversController<T>

    init(
        observerHost: ReplicaObserverHost,
        observersController: ObserversController<T>,
        observerId: UUID = UUID()
    ) async {
        self.observerHost = observerHost
        self.observersController = observersController
        self.observerId = observerId

        let (stream, continuation) = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.replicaStateFlow = stream
        self.stateContinuation = continuation

        _Concurrency.Task { [weak self] in
            guard let self else {
                return
            }
            await self.launchObserverControlling()
        }
    }

    func cancelObserving() async {
        observerControllingTask?.cancel()
        observerControllingTask = nil

        stateObservingTask?.cancel()
        stateObservingTask = nil

        errorsObservingTask?.cancel()
        errorsObservingTask = nil

        stateContinuation?.finish()
        errorContinuation?.finish()
    }


    /// Запускает задачу управления наблюдателем (добавление, активация, удаление).
    /// - Note: Отслеживает активность наблюдателя и уведомляет контроллер о его состоянии.
    private func launchObserverControlling() {
        observerControllingTask = _Concurrency.Task { [weak self] in
            guard let self else {
                return
            }

            var initialActive: Bool?
           /// Использует цикл for await для получения значений из потока observerHost.observerActive
            for await active in observerHost.observerActive {
                if let initial = initialActive {
                    if active {
                        await observersController.onObserverActive(observerId: observerId)
                    } else {
                        await observersController.onObserverInactive(observerId: observerId)
                    }
                } else {
                    /// Если это первое значение (initialActive == nil)
                    /// регистрирует наблюдателя с начальным статусом активности.
                    await observersController.onObserverAdded(observerId: observerId, active: active)
                    initialActive = active
                }
            }

            await observersController.onObserverRemoved(observerId: observerId)
        }
    }

    /// Запускает задачу наблюдения за состоянием реплики.
    private func launchStateObserving() {
        stateObservingTask = _Concurrency.Task { [weak self] in
            guard let self else {
                return
            }

            for await replicaState in replicaStateFlow {
                if _Concurrency.Task.isCancelled {
                    break
                }

                await stateContinuation?.yield(replicaState)
            }
        }
    }
}
