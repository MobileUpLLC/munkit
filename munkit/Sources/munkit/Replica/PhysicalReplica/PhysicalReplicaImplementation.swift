//
//  PhysicalReplicaImplementation.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

public actor PhysicalReplicaImplementation<T: Sendable>: PhysicalReplica {
    public let name: String

    private let storage: (any Storage<T>)?
    private let dataFetcher: @Sendable () async throws -> T
    private var replicaState: ReplicaState<T>

    private var observerStateStreams: [AsyncStreamBundle<ReplicaState<T>>] = []
    private var observerEventStreams: [AsyncStreamBundle<ReplicaEvent<T>>] = []

    private let observersControllerStateStream: AsyncStreamBundle<ReplicaState<T>>
    private let observersControllerEventStream: AsyncStreamBundle<ReplicaEvent<T>>

    private let loadingControllerStateStream: AsyncStreamBundle<ReplicaState<T>>
    private let loadingControllerEventStream: AsyncStreamBundle<ReplicaEvent<T>>

    private let clearingControllerStateStream: AsyncStreamBundle<ReplicaState<T>>
    private let clearingControllerEventStream: AsyncStreamBundle<ReplicaEvent<T>>

    private let freshnessControllerStateStream: AsyncStreamBundle<ReplicaState<T>>
    private let freshnessControllerEventStream: AsyncStreamBundle<ReplicaEvent<T>>

    private let dataMutationControllerStateStream: AsyncStreamBundle<ReplicaState<T>>
    private let dataMutationControllerEventStream: AsyncStreamBundle<ReplicaEvent<T>>

    private let optimisticUpdatesControllerStateStream: AsyncStreamBundle<ReplicaState<T>>
    private let optimisticUpdatesControllerEventStream: AsyncStreamBundle<ReplicaEvent<T>>

    private let observersController: ReplicaObserversController<T>
    private let loadingController: ReplicaLoadingController<T>
    private let clearingController: ReplicaClearingController<T>
    private let freshnessController: ReplicaFreshnessController<T>
    private let dataMutationController: ReplicaDataChangingController<T>
    private let optimisticUpdatesController: ReplicaOptimisticUpdatesController<T>

    public init(storage: (any Storage<T>)?, fetcher: @Sendable @escaping () async throws -> T, name: String) {
        self.name = name
        self.storage = storage
        self.dataFetcher = fetcher
        self.replicaState = ReplicaState<T>.createEmpty(hasStorage: storage != nil)
        self.observersControllerStateStream = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.observersControllerEventStream = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.loadingControllerStateStream = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.loadingControllerEventStream = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.clearingControllerStateStream = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.clearingControllerEventStream = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.freshnessControllerStateStream = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.freshnessControllerEventStream = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.dataMutationControllerStateStream = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.dataMutationControllerEventStream = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.optimisticUpdatesControllerStateStream = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.optimisticUpdatesControllerEventStream = AsyncStream.makeStream(of: ReplicaEvent<T>.self)

        self.observersController = ReplicaObserversController(
            initialState: replicaState,
            stateStream: observersControllerStateStream.stream,
            eventStreamContinuation: observersControllerEventStream.continuation
        )
        let dataLoader = DataLoader(storage: storage, fetcher: fetcher)
        self.loadingController = ReplicaLoadingController(
            replicaState: replicaState,
            replicaStateStream: loadingControllerStateStream.stream,
            replicaEventStreamContinuation: loadingControllerEventStream.continuation,
            dataLoader: dataLoader
        )
        self.clearingController = ReplicaClearingController(
            replicaStateStream: clearingControllerStateStream.stream,
            replicaEventStreamContinuation: clearingControllerEventStream.continuation,
            storage: storage
        )
        self.freshnessController = ReplicaFreshnessController(
            replicaState: replicaState,
            replicaStateStream: freshnessControllerStateStream.stream,
            replicaEventStreamContinuation: freshnessControllerEventStream.continuation
        )
        self.dataMutationController = ReplicaDataChangingController(
            replicaState: replicaState,
            replicaStateStream: dataMutationControllerStateStream.stream,
            replicaEventStreamContinuation: dataMutationControllerEventStream.continuation,
            storage: storage
        )
        self.optimisticUpdatesController = ReplicaOptimisticUpdatesController(
            replicaState: replicaState,
            replicaStateStream: optimisticUpdatesControllerStateStream.stream,
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

    private func processEvents() {
        Task {
            for await event in loadingControllerEventStream.stream {
                handleEvent(event)
            }
        }

        Task {
            for await event in observersControllerEventStream.stream {
                handleEvent(event)
            }
        }

        Task {
            for await event in clearingControllerEventStream.stream {
                handleEvent(event)
            }
        }

        Task {
            for await event in freshnessControllerEventStream.stream {
                handleEvent(event)
            }
        }

        Task {
            for await event in dataMutationControllerEventStream.stream {
                handleEvent(event)
            }
        }

        Task {
            for await event in optimisticUpdatesControllerEventStream.stream {
                handleEvent(event)
            }
        }
    }

    private func updateState(_ newState: ReplicaState<T>) {
        print("💾 Replica \(self) updated state: \(newState)")
        replicaState = newState

        let allStateStreams = observerStateStreams + [
            loadingControllerStateStream,
            observersControllerStateStream,
            freshnessControllerStateStream,
            clearingControllerStateStream,
            dataMutationControllerStateStream,
            optimisticUpdatesControllerStateStream
        ]

        allStateStreams.forEach { $0.continuation.yield(replicaState) }
    }

    private func handleEvent(_ event: ReplicaEvent<T>) {
        print("\n⚡️ \(self) received event: \(event)")

        switch event {
        case .loading(let loadingEvent):
            handleLoadingEvent(loadingEvent)
        case .freshness(let freshnessEvent):
            handleFreshnessEvent(freshnessEvent)
        case .cleared:
            var state = replicaState
            state.data = nil
            state.error = nil
            state.loadingFromStorageRequired = false
            updateState(state)
        case .clearedError:
            var state = replicaState
            state.error = nil
            updateState(state)
        case .observerCountChanged(let observingState):
            let previousState = replicaState
            let updatedState = replicaState.copy(observingState: observingState)
            updateState(updatedState)

            if observingState.activeObserverIds.count > previousState.observingState.activeObserverIds.count {
                Task { await revalidate() }
            }
        case .changing(let changingEvent):
            handleDataMutationEvent(changingEvent)
        case .optimisticUpdates(let optimisticUpdateEvent):
            handleOptimisticUpdateEvent(optimisticUpdateEvent)
        }
    }

    private func handleOptimisticUpdateEvent(_ event: OptimisticUpdatesEvent<T>) {
        switch event {
        case .begin(data: let data):
            let updatedState = replicaState.copy(data: data)
            updateState(updatedState)
        case .commit(data: let data):
            let updatedState = replicaState.copy(data: data)
            updateState(updatedState)
        case .rollback(data: let data):
            let updatedState = replicaState.copy(data: data)
            updateState(updatedState)
        }
    }

    private func handleDataMutationEvent(_ event: ChangingDataEvent<T>) {
        switch event {
        case .dataSetting(data: let data):
            let updatedState = replicaState.copy(
                data: data,
                loadingFromStorageRequired: false
            )
            updateState(updatedState)
        case .dataMutating(data: let data):
            let updatedState = replicaState.copy(
                data: data,
                loadingFromStorageRequired: false
            )
            updateState(updatedState)
        }
    }

    private func handleLoadingEvent(_ event: LoadingEvent<T>) {
        switch event {
        case .loadingStarted:
            var state = replicaState
            state.loading = true
            state.error = nil
            state.dataRequested = true
            updateState(state)
        case .dataFromStorageLoaded(let data):
            let updatedState = replicaState.copy(
                data: data,
                loadingFromStorageRequired: false
            )
            updateState(updatedState)
        case .loadingFinished(let event):
            handleLoadingFinishedEvent(event)
        }
    }

    private func handleFreshnessEvent(_ event: FreshnessEvent) {
        switch event {
        case .freshened:
            var state = replicaState
            state.data?.isFresh = true
            updateState(state)
        case .becameStale:
            var state = replicaState
            state.data?.isFresh = false
            updateState(state)
        }
    }

    private func handleLoadingFinishedEvent(_ event: LoadingFinished<T>) {
        switch event {
        case .success(let data):
            var state = replicaState
            state.loading = false
            state.data = data
            state.error = nil
            state.dataRequested = false
            state.preloading = false
            updateState(state)
        case .canceled:
            let updatedState = replicaState.copy(
                loading: false,
                dataRequested: false,
                preloading: false
            )
            updateState(updatedState)
        case .error(let error):
            let updatedState = replicaState.copy(
                loading: false,
                error: error,
                dataRequested: false,
                preloading: false
            )
            updateState(updatedState)
        }
    }

    func startOptimisticUpdate(_ update: any OptimisticUpdate<T>) async {
        await optimisticUpdatesController.beginOptimisticUpdate(update: update)
    }

    func commitOptimisticUpdate(_ update: any OptimisticUpdate<T>) async {
        await optimisticUpdatesController.commitOptimisticUpdate(update: update)
    }

    func rollbackOptimisticUpdate(_ update: any OptimisticUpdate<T>) async {
        await optimisticUpdatesController.rollbackOptimisticUpdate(update: update)
    }

    public func withOptimisticUpdate(
        update: any OptimisticUpdate<T>,
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
}
