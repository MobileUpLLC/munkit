//
//  PhysicalReplicaImplementation.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

public actor PhysicalReplicaImplementation<T: Sendable>: PhysicalReplica {
    public let name: String
    public var settings: ReplicaSettings

    private let storage: (any Storage<T>)?
    private let dataFetcher: @Sendable () async throws -> T
    private var replicaState: ReplicaState<T>

    private var observerStateStreams: [AsyncStreamBundle<ReplicaState<T>>] = []
    private var observerEventStreams: [AsyncStreamBundle<ReplicaEvent<T>>] = []

    private let observersControllerEventStream: AsyncStreamBundle<ReplicaEvent<T>>
    private let loadingControllerEventStream: AsyncStreamBundle<ReplicaEvent<T>>
    private let clearingControllerEventStream: AsyncStreamBundle<ReplicaEvent<T>>
    private let freshnessControllerEventStream: AsyncStreamBundle<ReplicaEvent<T>>
    private let dataMutationControllerEventStream: AsyncStreamBundle<ReplicaEvent<T>>
    private let optimisticUpdatesControllerEventStream: AsyncStreamBundle<ReplicaEvent<T>>

    private let observersController: ReplicaObserversController<T>
    private let loadingController: ReplicaLoadingController<T>
    private let clearingController: ReplicaClearingController<T>
    private let freshnessController: ReplicaFreshnessController<T>
    private let dataMutationController: ReplicaDataChangingController<T>
    private let optimisticUpdatesController: ReplicaOptimisticUpdatesController<T>

    public init(
        name: String,
        settings: ReplicaSettings,
        storage: (any Storage<T>)?,
        fetcher: @Sendable @escaping () async throws -> T
    ) {
        self.name = name
        self.settings = settings
        self.storage = storage
        self.dataFetcher = fetcher
        self.replicaState = ReplicaState<T>.createEmpty(hasStorage: storage != nil)
        self.observersControllerEventStream = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.loadingControllerEventStream = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.clearingControllerEventStream = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.freshnessControllerEventStream = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.dataMutationControllerEventStream = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.optimisticUpdatesControllerEventStream = AsyncStream.makeStream(of: ReplicaEvent<T>.self)

        self.observersController = ReplicaObserversController(
            initialState: replicaState,
            eventStreamContinuation: observersControllerEventStream.continuation
        )
        let dataLoader = DataLoader(storage: storage, fetcher: fetcher)
        self.loadingController = ReplicaLoadingController(
            replicaState: replicaState,
            replicaEventStreamContinuation: loadingControllerEventStream.continuation,
            dataLoader: dataLoader
        )
        self.clearingController = ReplicaClearingController(
            replicaEventStreamContinuation: clearingControllerEventStream.continuation,
            storage: storage
        )
        self.freshnessController = ReplicaFreshnessController(
            replicaState: replicaState,
            replicaEventStreamContinuation: freshnessControllerEventStream.continuation,
            staleTime: settings.staleTime
        )
        self.dataMutationController = ReplicaDataChangingController(
            replicaState: replicaState,
            replicaEventStreamContinuation: dataMutationControllerEventStream.continuation,
            storage: storage
        )
        self.optimisticUpdatesController = ReplicaOptimisticUpdatesController(
            replicaState: replicaState,
            replicaEventStreamContinuation: optimisticUpdatesControllerEventStream.continuation,
            storage: storage
        )

        Task {
            await processEvents()
        }
    }

    public func observe(activityStream: AsyncStream<Bool>) async -> ReplicaObserver<T> {
        let stateStreamBundle = AsyncStream<ReplicaState<T>>.makeStream()
        observerStateStreams.append(stateStreamBundle)

        let eventStreamBundle = AsyncStream<ReplicaEvent<T>>.makeStream()
        observerEventStreams.append(eventStreamBundle)

        return await ReplicaObserver<T>(
            activityStream: activityStream,
            stateStream: stateStreamBundle.stream,
            eventStream: eventStreamBundle.stream,
            observersController: observersController
        )
    }

    public func refresh() async {
        await loadingController.refresh()
    }

    public func revalidate() async {
        await loadingController.revalidate()
    }

    public func fetchData(forceRefresh: Bool) async throws -> T {
        try await loadingController.getData(forceRefresh: forceRefresh)
    }

    public func clear(invalidationMode: InvalidationMode, removeFromStorage: Bool) async {
        await loadingController.cancel()
        try? await clearingController.clear(removeFromStorage: removeFromStorage)
        Task {
            await loadingController.refreshAfterInvalidation(invalidationMode: invalidationMode)
        }
    }

    public func clearError() async {
        await clearingController.clearError()
    }

    public func invalidate(mode: InvalidationMode) {
        Task {
            await freshnessController.invalidate()
            await loadingController.refreshAfterInvalidation(invalidationMode: mode)
        }
    }

    public func markAsFresh() async {
        await freshnessController.makeFresh()
    }

    public func setData(_ data: T) async {
        try? await dataMutationController.setData(data: data)
    }

    public func mutateData(transform: @escaping (T) -> T) {
        Task {
            try? await dataMutationController.mutateData(transform: transform)
        }
    }

    func cancel() async {
        await loadingController.cancel()
    }

    func startOptimisticUpdate(_ update: OptimisticUpdate<T>) async {
        await optimisticUpdatesController.beginOptimisticUpdate(update: update)
    }

    func commitOptimisticUpdate(_ update: OptimisticUpdate<T>) async {
        await optimisticUpdatesController.commitOptimisticUpdate(update: update)
    }

    func rollbackOptimisticUpdate(_ update: OptimisticUpdate<T>) async {
        await optimisticUpdatesController.rollbackOptimisticUpdate(update: update)
    }

    public func withOptimisticUpdate(
        update: OptimisticUpdate<T>,
        onSuccess: (@Sendable () async -> Void)? = nil,
        onError: (@Sendable (Error) async -> Void)? = nil,
        onCanceled: (@Sendable () async -> Void)? = nil,
        onFinished: (@Sendable () async -> Void)? = nil,
        block: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        await startOptimisticUpdate(update)

        do {
            let result = try await block()
            await commitOptimisticUpdate(update)

            if let onSuccess {
                await onSuccess()
            }

            if let onFinished {
                await onFinished()
            }

            return result
        } catch {
            await rollbackOptimisticUpdate(update)

            if let onError {
                await onError(error)
            }

            if let onFinished {
                await onFinished()
            }

            throw error
        }
    }

    private func processEvents() {
        let eventStreams = [
            loadingControllerEventStream.stream,
            observersControllerEventStream.stream,
            clearingControllerEventStream.stream,
            freshnessControllerEventStream.stream,
            dataMutationControllerEventStream.stream,
            optimisticUpdatesControllerEventStream.stream
        ]

        Task {
            await withTaskGroup { group in
                for stream in eventStreams {
                    group.addTask { [weak self] in
                        for await event in stream {
                            await self?.handleEvent(event)
                        }
                    }
                }
            }
        }
    }

    private func updateState(_ newState: ReplicaState<T>) async {
        print("⚖️", name, #function, newState)

        replicaState = newState

        await observersController.updateState(newState)
        await loadingController.updateState(newState)
        await clearingController.updateState(newState)
        await freshnessController.updateState(newState)
        await dataMutationController.updateState(newState)
        await optimisticUpdatesController.updateState(newState)

        observerStateStreams.forEach { $0.continuation.yield(replicaState) }
    }

    private func handleEvent(_ event: ReplicaEvent<T>) async {
        print("⚡️", name, #function, event)

        switch event {
        case .loading(let loadingEvent):
            await handleLoadingEvent(loadingEvent)
        case .freshness(let freshnessEvent):
            await handleFreshnessEvent(freshnessEvent)
        case .cleared:
            await handleClearedEvent()
        case .clearedError:
            await handleClearedErrorEvent()
        case .observerCountChanged(let observingState):
            await handleObserverCountChangedEvent(observingState: observingState)
        case .changing(let changingEvent):
            await handleDataMutationEvent(changingEvent)
        case .optimisticUpdates(let optimisticUpdateEvent):
            await handleOptimisticUpdateEvent(optimisticUpdateEvent)
        }
    }

    private func handleClearedEvent() async {
        let updatedState = replicaState.copy(data: nil, error: nil, loadingFromStorageRequired: false)
        await updateState(updatedState)
    }

    private func handleClearedErrorEvent() async {
        let updatedState = replicaState.copy(error: nil)
        await updateState(updatedState)
    }

    private func handleObserverCountChangedEvent(observingState: ObservingState) async {
        let previousState = replicaState
        let updatedState = replicaState.copy(observingState: observingState)
        await updateState(updatedState)

        if observingState.activeObserverIds.count > previousState.observingState.activeObserverIds.count {
            await revalidate()
        }
    }

    private func handleOptimisticUpdateEvent(_ event: OptimisticUpdatesEvent<T>) async {
        switch event {
        case .begin(data: let data):
            let updatedState = replicaState.copy(data: data)
            await updateState(updatedState)
        case .commit(data: let data):
            let updatedState = replicaState.copy(data: data)
            await updateState(updatedState)
        case .rollback(data: let data):
            let updatedState = replicaState.copy(data: data)
            await updateState(updatedState)
        }
    }

    private func handleDataMutationEvent(_ event: ChangingDataEvent<T>) async {
        switch event {
        case .dataSetting(data: let data):
            let updatedState = replicaState.copy(
                data: data,
                loadingFromStorageRequired: false
            )
            await updateState(updatedState)
        case .dataMutating(data: let data):
            let updatedState = replicaState.copy(
                data: data,
                loadingFromStorageRequired: false
            )
            await updateState(updatedState)
        }
    }

    private func handleLoadingEvent(_ event: LoadingEvent<T>) async {
        switch event {
        case .loadingStarted:
            let updatedState = replicaState.copy(
                loading: true,
                error: nil,
                dataRequested: true
            )
            await updateState(updatedState)
        case .dataFromStorageLoaded(let data):
            let updatedState = replicaState.copy(
                data: data,
                loadingFromStorageRequired: false
            )
            await updateState(updatedState)
        case .loadingFinished(let event):
            await handleLoadingFinishedEvent(event)
        }
    }

    private func handleFreshnessEvent(_ event: FreshnessEvent) async {
        switch event {
        case .freshened:
            if var data = replicaState.data {
                data.isFresh = true
                let updatedState = replicaState.copy(data: data)
                await updateState(updatedState)
            }
        case .becameStale:
            if var data = replicaState.data {
                data.isFresh = false
                let updatedState = replicaState.copy(data: data)
                await updateState(updatedState)
            }
        }
    }

    private func handleLoadingFinishedEvent(_ event: LoadingFinished<T>) async {
        switch event {
        case .success(let data):
            let updatedState = replicaState.copy(
                loading: false,
                data: data,
                error: nil,
                dataRequested: false,
                preloading: false
            )
            await updateState(updatedState)
            await freshnessController.makeFresh()
        case .canceled:
            let updatedState = replicaState.copy(
                loading: false,
                dataRequested: false,
                preloading: false
            )
            await updateState(updatedState)
        case .error(let error):
            let updatedState = replicaState.copy(
                loading: false,
                error: error,
                dataRequested: false,
                preloading: false
            )
            await updateState(updatedState)
        }
    }
}
