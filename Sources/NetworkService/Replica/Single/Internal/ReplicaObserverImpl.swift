//
//  ReplicaObserverImpl.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 19.03.2025.
//

import Foundation

actor ReplicaObserverImpl<T: AnyObject & Sendable>: ReplicaObserver {
    private let observerId: UUID
    private let observerHost: any ReplicaObserverHost
    private let replicaStateFlow: AsyncStream<ReplicaState<T>>
    private let replicaEventFlow: AsyncStream<ReplicaEvent<T>>
    private let observersController: ObserversController<T>

    private var stateContinuation: AsyncStream<LoadableReplicaState<T>>.Continuation?
    private var errorContinuation: AsyncStream<LoadingError>.Continuation?

    private var observerControllingTask: _Concurrency.Task<Void, Never>?
    private var stateObservingTask: _Concurrency.Task<Void, Never>?
    private var errorsObservingTask: _Concurrency.Task<Void, Never>?

    init(
        observerHost: any ReplicaObserverHost,
        replicaStateFlow: AsyncStream<ReplicaState<T>>,
        replicaEventFlow: AsyncStream<ReplicaEvent<T>>,
        observersController: ObserversController<T>,
        observerId: UUID = UUID()
    ) async {
        self.observerHost = observerHost
        self.replicaStateFlow = replicaStateFlow
        self.replicaEventFlow = replicaEventFlow
        self.observersController = observersController
        self.observerId = observerId

        _Concurrency.Task { [weak self] in
            guard let self else {
                return
            }
            await self.launchObserverControlling()
            await self.launchStateObserving()
            await self.launchLoadingErrorsObserving()
        }
    }

    func getStateFlow() async -> AsyncStream<LoadableReplicaState<T>> {
        AsyncStream { continuation in
            self.stateContinuation = continuation
            continuation.yield(LoadableReplicaState<T>())
        }
    }

    func getLoadingErrorFlow() async -> AsyncStream<LoadingError> {
        AsyncStream { continuation in
            self.errorContinuation = continuation
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
                    /// Если это первое значение (initialActive == nil) для
                    /// регистрирует наблюдателя с начальным статусом активности.
                    await observersController.onObserverAdded(observerId: observerId, active: active)
                    initialActive = active
                }
            }
            await observersController.onObserverRemoved(observerId: observerId)
        }
    }

    private func launchStateObserving() {
        stateObservingTask = _Concurrency.Task { [weak self] in
            guard let self else { return }

            let activeFlow = observerHost.observerActive
            var activeIterator = activeFlow.makeAsyncIterator()
            var currentActive = await activeIterator.next() ?? false

            for await state in replicaStateFlow {
                if currentActive {
                    await stateContinuation?.yield(state.getLoadable())
                }
                if let nextActive = await activeIterator.next() {
                    currentActive = nextActive
                }
            }
        }
    }

    private func launchLoadingErrorsObserving() {
        errorsObservingTask = _Concurrency.Task { [weak self] in
            guard let self else { return }

            let activeFlow = observerHost.observerActive
            var activeIterator = activeFlow.makeAsyncIterator()
            var currentActive = await activeIterator.next() ?? false

            for await event in replicaEventFlow {
                if currentActive {
                    switch event {
                    case .loading(let loadingEvent):
                        switch loadingEvent {
                        case .loadingFinished(.error(let exception)):
                            await errorContinuation?.yield(LoadingError(reason: .normal, error: exception))
                        default:
                            break
                        }
                    default:
                        break
                    }
                }
                if let nextActive = await activeIterator.next() {
                    currentActive = nextActive
                }
            }
        }
    }
}
