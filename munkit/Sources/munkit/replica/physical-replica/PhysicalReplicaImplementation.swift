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
    private let dataLoader: DataLoader<T>

    private var observerStateStreams: [AsyncStreamBundle<ReplicaState<T>>] = []
    private var dataClearingTask: Task<Void, Error>?
    private var errorClearingTask: Task<Void, Error>?
    private var cancelTask: Task<Void, Error>?
    private var staleTask: Task<Void, Error>?

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
        self.dataLoader = DataLoader(storage: storage, fetcher: fetcher)

        Task {
            await processDataLoaderOutput()
        }
    }

    // MARK: - Additional Public Methods

    public func observe(activityStream: AsyncStream<Bool>) async -> ReplicaObserver<T> {
        let stateStreamBundle = AsyncStream<ReplicaState<T>>.makeStream()
        observerStateStreams.append(stateStreamBundle)

        return await ReplicaObserver<T>(
            activityStream: activityStream,
            stateStream: stateStreamBundle.stream,
            observerDelegate: self
        )
    }

    public func refresh() async {
        await loadData(skipLoadingIfFresh: false)
    }

    public func revalidate() async {
        await loadData(skipLoadingIfFresh: true)
    }

    public func fetchData(forceRefresh: Bool) async throws -> T {
        if !forceRefresh, let data = replicaState.data, data.isFresh {
            return data.value
        }

        let outputStream = AsyncStream<DataLoader<T>.Output> { continuation in
            Task {
                await loadData(skipLoadingIfFresh: false, setDataRequested: true)
                for await output in dataLoader.outputStreamBundle.stream {
                    continuation.yield(output)
                    if case .loadingFinished = output {
                        continuation.finish()
                    }
                }
            }
        }

        for await output in outputStream {
            switch output {
            case .loadingFinished(.success(let data)):
                return data
            case .loadingFinished(.error(let error)):
                throw error
            default:
                continue
            }
        }
        throw LoadingError()
    }

    public func cancel() async {
        guard replicaState.loading else { return }
        await dataLoader.cancel()
        var updatedState = replicaState
        updatedState.loading = false
        updatedState.dataRequested = false
        updatedState.preloading = false
        await updateState(updatedState)
    }

    // MARK: - Observer Management

    private func emitObserverCountChangedIfNeeded(
        from previousState: ObservingState,
        to newState: ObservingState
    ) async {
        if previousState.observerIds.count != newState.observerIds.count
            || previousState.activeObserverIds.count != newState.activeObserverIds.count {
            var updatedState = replicaState
            updatedState.observingState = newState
            await updateState(updatedState)
            if newState.activeObserverIds.count > previousState.activeObserverIds.count {
                await revalidate()
            }
        }
    }

    // MARK: - Data Loading

    private func loadData(skipLoadingIfFresh: Bool, setDataRequested: Bool = false) async {
        guard
            !replicaState.loading,
            !(skipLoadingIfFresh && replicaState.hasFreshData)
        else {
            return
        }

        await dataLoader.load(loadingFromStorageRequired: replicaState.loadingFromStorageRequired)

        let dataRequested: Bool = setDataRequested || replicaState.dataRequested
        let preloading: Bool = (replicaState.observingState.status == .none) || replicaState.preloading

        var updatedState = replicaState
        updatedState.loading = true
        updatedState.error = nil
        updatedState.dataRequested = dataRequested
        updatedState.preloading = preloading

        await updateState(updatedState)
    }

    private func refreshAfterInvalidation(invalidationMode: InvalidationMode) async {
        if replicaState.loading {
            await cancel()
            await refresh()
            return
        }

        switch invalidationMode {
        case .dontRefresh:
            break
        case .refreshIfHasObservers:
            if replicaState.observingState.status != .none {
                await refresh()
            }
        case .refreshIfHasActiveObservers:
            if replicaState.observingState.status == .active {
                await refresh()
            }
        case .refreshAlways:
            await refresh()
        }
    }

    private func processDataLoaderOutput() async {
        for await output in dataLoader.outputStreamBundle.stream {
            print("📥", #function, output)
            switch output {
            case .storageRead(.data(let data)):
                let data = ReplicaData(value: data, isFresh: false, changingDate: .now)
                if replicaState.data == nil {
                    var updatedState = replicaState
                    updatedState.data = data
                    updatedState.loadingFromStorageRequired = false
                    await updateState(updatedState)
                }

            case .storageRead(.empty):
                fatalError()

            case .loadingFinished(.success(let data)):
                let data = ReplicaData(
                    value: data,
                    isFresh: true,
                    changingDate: .now
                )
                var updatedState = replicaState

                updatedState.loading = false
                updatedState.data = data
                updatedState.error = nil
                updatedState.dataRequested = false
                updatedState.preloading = false

                if settings.staleTime < .infinity {
                    staleTask?.cancel()
                    staleTask = Task {
                        try await Task.sleep(for: .seconds(settings.staleTime))
                        if let data = replicaState.data, data.isFresh {
                            var newData = replicaState.data
                            newData?.isFresh = false
                            var updatedState = replicaState
                            updatedState.data = newData
                            await updateState(updatedState)
                        }
                    }
                }

                await updateState(updatedState)

            case .loadingFinished(.error(let error)):
                var updatedState = replicaState
                updatedState.loading = false
                updatedState.error = error
                updatedState.dataRequested = false
                updatedState.preloading = false

                await updateState(updatedState)
            }
        }
    }

    // MARK: - Clearing

    private func clearData(removeFromStorage: Bool) async throws {
        var updatedState = replicaState
        updatedState.data = nil
        updatedState.error = nil
        updatedState.loadingFromStorageRequired = storage != nil
        await updateState(updatedState)
        if removeFromStorage {
            try await storage?.remove()
        }
    }

    // MARK: - State Management

    private func updateState(_ newState: ReplicaState<T>) async {
        logStateChange(from: replicaState, to: newState)
        replicaState = newState
        observerStateStreams.forEach { $0.continuation.yield(replicaState) }
    }

    private func logStateChange(from oldState: ReplicaState<T>, to newState: ReplicaState<T>) {
        var changes: [String] = []

        if oldState.loading != newState.loading {
            changes.append("loading: \(oldState.loading) → \(newState.loading)")
        }
        if (oldState.data == nil) != (newState.data == nil) {
            changes.append("data: \(oldState.data != nil ? "present" : "absent") → \(newState.data != nil ? "present" : "absent")")
        }
        if oldState.error?.localizedDescription != newState.error?.localizedDescription {
            changes.append("error: \(oldState.error?.localizedDescription ?? "none") → \(newState.error?.localizedDescription ?? "none")")
        }
        if oldState.observingState.observerIds != newState.observingState.observerIds {
            changes.append("observing: \(oldState.observingState) → \(newState.observingState)")
        }
        if oldState.dataRequested != newState.dataRequested {
            changes.append("dataRequested: \(oldState.dataRequested) → \(newState.dataRequested)")
        }
        if oldState.preloading != newState.preloading {
            changes.append("preloading: \(oldState.preloading) → \(newState.preloading)")
        }
        if oldState.loadingFromStorageRequired != newState.loadingFromStorageRequired {
            changes.append("loadingFromStorageRequired: \(oldState.loadingFromStorageRequired) → \(newState.loadingFromStorageRequired)")
        }
        if oldState.hasFreshData != newState.hasFreshData {
            changes.append("hasFreshData: \(oldState.hasFreshData) → \(newState.hasFreshData)")
        }

        if changes.isEmpty {
            print("⚖️ \(name) \(#function): No changes in state")
        } else {
            print("⚖️ \(name) \(#function): Changed fields:\n  " + changes.joined(separator: "\n  "))
        }
    }

    private func performDataClearing(after seconds: TimeInterval) async {
        try? await Task.sleep(for: .seconds(seconds))
        let replicaState = await replicaState
        guard
            (replicaState.data != nil || replicaState.error != nil),
            !replicaState.loading,
            case .none = replicaState.observingState.status
        else {
            return
        }
        try? await clearData(removeFromStorage: false)
    }

    private func performErrorClearing(after seconds: TimeInterval) async {
        try? await Task.sleep(for: .seconds(seconds))
        let replicaState = await replicaState
        guard
            replicaState.error != nil,
            !replicaState.loading,
            case .none = replicaState.observingState.status
        else {
            return
        }
        await clearError()
    }

    private func performCancel(after seconds: TimeInterval) async {
        try? await Task.sleep(for: .seconds(seconds))
        let replicaState = await replicaState
        guard
            replicaState.loading,
            !replicaState.dataRequested,
            case .none = replicaState.observingState.status
        else {
            return
        }
        await cancel()
    }

    private func clearError() async {
        var updatedState = replicaState
        updatedState.error = nil
        await updateState(updatedState)
    }
}

extension PhysicalReplicaImplementation: ReplicaObserverDelegate {
    func handleObserverAdded(observerId: UUID, isActive: Bool) async {
        [errorClearingTask, dataClearingTask, cancelTask].forEach { $0?.cancel() }

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

        await emitObserverCountChangedIfNeeded(from: currentObservingState, to: newObservingState)
    }

    func handleObserverRemoved(observerId: UUID) async {
        let currentObservingState = replicaState.observingState
        let isLastActive = currentObservingState.activeObserverIds.count == 1
            && currentObservingState.activeObserverIds.contains(observerId)
        let updatedObservingTime = isLastActive ? .timeInPast(.now) : currentObservingState.observingTime
        let newObservingState = ObservingState(
            observerIds: currentObservingState.observerIds.subtracting([observerId]),
            activeObserverIds: currentObservingState.activeObserverIds.subtracting([observerId]),
            observingTime: updatedObservingTime
        )

        await emitObserverCountChangedIfNeeded(from: currentObservingState, to: newObservingState)

        guard newObservingState.status == .none else {
            return
        }

        let cancelTime = settings.cancelTime
        if cancelTime < .infinity {
            cancelTask?.cancel()
            cancelTask = Task { [weak self] in await self?.performCancel(after: cancelTime) }
        }

        let clearTime = settings.clearTime
        if clearTime < .infinity {
            dataClearingTask?.cancel()
            dataClearingTask = Task { [weak self] in await self?.performDataClearing(after: clearTime) }
        }

        let clearErrorTime = settings.clearErrorTime
        if clearErrorTime < .infinity {
            errorClearingTask?.cancel()
            errorClearingTask = Task { [weak self] in await self?.performErrorClearing(after: clearErrorTime) }
        }
    }

    func handleObserverActivated(observerId: UUID) async {
        let currentObservingState = replicaState.observingState
        var updatedActiveObserverIds = currentObservingState.activeObserverIds
        updatedActiveObserverIds.insert(observerId)
        let newObservingState = ObservingState(
            observerIds: currentObservingState.observerIds,
            activeObserverIds: updatedActiveObserverIds,
            observingTime: .now
        )

        await emitObserverCountChangedIfNeeded(from: currentObservingState, to: newObservingState)
    }

    func handleObserverDeactivated(observerId: UUID) async {
        let currentObservingState = replicaState.observingState
        let isLastActive = currentObservingState.activeObserverIds.count == 1
            && currentObservingState.activeObserverIds.contains(observerId)
        let updatedObservingTime = isLastActive ? .timeInPast(.now) : currentObservingState.observingTime
        let newObservingState = ObservingState(
            observerIds: currentObservingState.observerIds,
            activeObserverIds: currentObservingState.activeObserverIds.subtracting([observerId]),
            observingTime: updatedObservingTime
        )

        await emitObserverCountChangedIfNeeded(from: currentObservingState, to: newObservingState)
    }
}
