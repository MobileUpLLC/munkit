//
//  PhysicalReplicaImplementation.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

public actor PhysicalReplicaImplementation<T: Sendable>: PhysicalReplica {
    public let name: String

    private let identifier: UUID
    private let storage: (any Storage<T>)?
    private let fetcher: Fetcher<T>
    private var currentReplicaState: ReplicaState<T>

    private var observerStateStreamBundles: [AsyncStreamBundle<ReplicaState<T>>] = []
    private var observerEventStreamBundles: [AsyncStreamBundle<ReplicaEvent<T>>] = []

    private let observersControllerStateStreamBundle: AsyncStreamBundle<ReplicaState<T>>
    private let observersControllerEventStreamBundle: AsyncStreamBundle<ReplicaEvent<T>>

    private let loadingControllerStateStreamBundle: AsyncStreamBundle<ReplicaState<T>>
    private let loadingControllerEventStreamBundle: AsyncStreamBundle<ReplicaEvent<T>>

    private let сlearingControllerStateStreamBundle: AsyncStreamBundle<ReplicaState<T>>
    private let сlearingControllerEventStreamBundle: AsyncStreamBundle<ReplicaEvent<T>>

    private let freshnessControllerStateStreamBundle: AsyncStreamBundle<ReplicaState<T>>
    private let freshnessControllerEventStreamBundle: AsyncStreamBundle<ReplicaEvent<T>>

    private let replicaObserversController: ReplicaObserversController<T>
    private let replicaLoadingController: ReplicaLoadingController<T>
    private let replicaClearingController: ReplicaClearingController<T>
    private let replicaFreshnessController: ReplicaFreshnessController<T>

    public init(id: UUID = UUID(), storage: (any Storage<T>)?, fetcher: @escaping Fetcher<T>, name: String) {
        self.identifier = id
        self.name = name
        self.storage = storage
        self.fetcher = fetcher
        self.currentReplicaState = ReplicaState<T>.createEmpty(hasStorage: storage != nil)
        self.observersControllerStateStreamBundle = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.observersControllerEventStreamBundle = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.loadingControllerStateStreamBundle = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.loadingControllerEventStreamBundle = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.сlearingControllerStateStreamBundle = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.сlearingControllerEventStreamBundle = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.freshnessControllerStateStreamBundle = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.freshnessControllerEventStreamBundle = AsyncStream.makeStream(of: ReplicaEvent<T>.self)

        self.replicaObserversController = ReplicaObserversController(
            replicaState: currentReplicaState,
            replicaStateStream: observersControllerStateStreamBundle.stream,
            replicaEventStreamContinuation: observersControllerEventStreamBundle.continuation
        )
        let dataLoader = DataLoader(storage: storage, fetcher: fetcher)
        self.replicaLoadingController = ReplicaLoadingController(
            replicaState: currentReplicaState,
            replicaStateStream: loadingControllerStateStreamBundle.stream,
            replicaEventStreamContinuation: loadingControllerEventStreamBundle.continuation,
            dataLoader: dataLoader
        )
        self.replicaClearingController = ReplicaClearingController(
            replicaStateStream: loadingControllerStateStreamBundle.stream,
            replicaEventStreamContinuation: loadingControllerEventStreamBundle.continuation,
            storage: storage
        )
        self.replicaFreshnessController = ReplicaFreshnessController(
            replicaState: currentReplicaState,
            replicaStateStream: loadingControllerStateStreamBundle.stream,
            replicaEventStreamContinuation: loadingControllerEventStreamBundle.continuation
        )

        Task {
            await processReplicaEvent()
        }
    }

    public func observe(observerActive: AsyncStream<Bool>) async -> ReplicaObserver<T> {
        let stateStreamPair = AsyncStream<ReplicaState<T>>.makeStream()
        observerStateStreamBundles.append(stateStreamPair)

        let eventStreamPair = AsyncStream<ReplicaEvent<T>>.makeStream()
        observerEventStreamBundles.append(eventStreamPair)

        return await ReplicaObserver<T>(
            observerActive: observerActive,
            replicaStateStream: stateStreamPair.stream,
            externalEventStream: eventStreamPair.stream,
            observersController: replicaObserversController
        )
    }

    public func refresh() async {
        await replicaLoadingController.refresh()
    }

    public func revalidate() async {
        await replicaLoadingController.revalidate()
    }

    public func getData(forceRefresh: Bool) async throws -> T {
        try await replicaLoadingController.getData(forceRefresh: forceRefresh)
    }

    public func clear(invalidationMode: InvalidationMode, removeFromStorage: Bool) async {
        await replicaLoadingController.cancel()
        try? await replicaClearingController.clear(removeFromStorage: removeFromStorage)
        Task {
            await replicaLoadingController.refreshAfterInvalidation(invalidationMode: invalidationMode)
        }
    }

    public func clearError() async {
        await replicaClearingController.clearError()
    }

    public func invalidate(mode: InvalidationMode) async {
        Task {
            await replicaFreshnessController.invalidate()
            await replicaLoadingController.refreshAfterInvalidation(invalidationMode: mode)
        }
    }

    public func makeFresh() async {
        await replicaFreshnessController.makeFresh()
    }

    func cancel() async {
        await replicaLoadingController.cancel()
    }
    
    private func processReplicaEvent() async {
        Task {
            for await event in loadingControllerEventStreamBundle.stream {
                processReplicaEvent(event)
            }
        }

        Task {
            for await event in observersControllerEventStreamBundle.stream {
                processReplicaEvent(event)
            }
        }
    }

    private func updateState(_ newState: ReplicaState<T>) {
        print("💾 Replica \(self) обновила состояние: \(newState)")
        currentReplicaState = newState

        let allStateStreamPairs = observerStateStreamBundles
            + [loadingControllerStateStreamBundle, observersControllerStateStreamBundle]

        allStateStreamPairs.forEach { $0.continuation.yield(currentReplicaState) }
    }

    private func processReplicaEvent(_ event: ReplicaEvent<T>) {
        print("\n⚡️ \(self) получено событие: \(event)")
        switch event {
        case .loading(let loadingEvent):
            handleLoadingEvent(loadingEvent)
        case .freshness(let freshnessEvent):
            handleFreshnessEvent(freshnessEvent)
        case .cleared:
            var replica = currentReplicaState
            replica.data = nil
            replica.error = nil
            replica.loadingFromStorageRequired = false

            updateState(replica)

        case .clearedError:
            var replica = currentReplicaState
            replica.error = nil

            updateState(replica)
        case .observerCountChanged(let observingState):
            let previousState = currentReplicaState
            updateState(currentReplicaState.copy(observingState: observingState))

            print("🔍 \(self) изменилось количество наблюдателей: observerIds \(observingState.observerIds) activeObserverIds: \(observingState.activeObserverIds) observingTime \(observingState.observingTime)")

            if observingState.activeObserverIds.count > previousState.observingState.activeObserverIds.count {
                Task { await revalidate() }
            }
        }
    }

    private func handleLoadingEvent(_ loadingEvent: LoadingEvent<T>) {
        switch loadingEvent {
        case .loadingStarted:
            var replica = currentReplicaState
            replica.loading = true
            replica.error = nil
            replica.dataRequested = true

            updateState(replica)

        case .dataFromStorageLoaded(let data):
            updateState(currentReplicaState.copy(
                data: data,
                loadingFromStorageRequired: false
            ))

        case .loadingFinished(let event):
            handleLoadingFinishedEvent(event)
        }
    }

    private func handleFreshnessEvent(_ freshnessEvent: FreshnessEvent) {
        switch freshnessEvent {
        case .freshened:
            var replica = currentReplicaState
            replica.data?.isFresh = true

            updateState(replica)
        case .becameStale:
            var replica = currentReplicaState
            replica.data?.isFresh = false

            updateState(replica)
        }
    }

    private func handleLoadingFinishedEvent(_ event: LoadingFinished<T>) {
        switch event {
        case .success(let data):
            var replica = currentReplicaState
            replica.loading = false
            replica.data = data
            replica.error = nil
            replica.dataRequested = false
            replica.preloading = false

            updateState(replica)

        case .canceled:
            updateState(currentReplicaState.copy(
                loading: false,
                dataRequested: false,
                preloading: false
            ))

        case .error(let error):
            updateState(currentReplicaState.copy(
                loading: false,
                error: error,
                dataRequested: false,
                preloading: false
            ))
        }
    }
}
