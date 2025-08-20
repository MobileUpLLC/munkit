//
//  SingleReplicaImplementation.swift
//  MUNKit
//
//  Created by Ilia Chub on 29.04.2025.
//

import Foundation

actor SingleReplicaImplementation<T: Sendable>: SingleReplica {
    public let name: String

    private let settings: ReplicaSettings
    private let storage: (any ReplicaStorage<T>)?
    private let dataFetcher: @Sendable () async throws -> T

    private var replicaState: ReplicaState<T>
    private var observerStateStreams: [AsyncStreamBundle<ReplicaState<T>>] = []
    private var dataClearingTask: Task<Void, Error>?
    private var errorClearingTask: Task<Void, Error>?
    private var cancelTask: Task<Void, Error>?
    private var staleTask: Task<Void, Error>?
    private var loadingTask: Task<Void, Never>?

    init(
        name: String,
        settings: ReplicaSettings,
        storage: (any ReplicaStorage<T>)?,
        fetcher: @Sendable @escaping () async throws -> T
    ) {
        self.name = name
        self.settings = settings
        self.storage = storage
        self.dataFetcher = fetcher

        let observingState = ReplicaObservingState(
            observerIds: [],
            activeObserverIds: [],
            lastObservingTime: .never
        )
        self.replicaState = ReplicaState(
            loading: false,
            data: nil,
            error: nil,
            observingState: observingState
        )
    }

    public func observe(activityStream: AsyncStream<Bool>) async -> ReplicaObserver<T> {
        let stateStreamBundle = AsyncStream<ReplicaState<T>>.makeStream()
        observerStateStreams.append(stateStreamBundle)

        let observer = await ReplicaObserver<T>(
            activityStream: activityStream,
            stateStream: stateStreamBundle.stream,
        )

        Task {
            for await event in observer.eventStream {
                await handleObserverEvent(event, observerId: observer.observerId)
            }
        }

        return observer
    }

    public func refresh() async {
        await setLoadingStateAndLoadData(skipLoadingIfFresh: false)
    }

    public func revalidate() async {
        await setLoadingStateAndLoadData(skipLoadingIfFresh: true)
    }

    private func cancel() async {
        guard replicaState.loading else { return }
        loadingTask?.cancel()
        var updatedState = replicaState
        updatedState.loading = false
        await updateState(updatedState)
    }

    private func emitObserverCountChangedIfNeeded(
        from previousState: ReplicaObservingState,
        to newState: ReplicaObservingState
    ) async {
        guard
            previousState.observerIds.count != newState.observerIds.count
            || previousState.activeObserverIds.count != newState.activeObserverIds.count
        else {
            return
        }

        var updatedState = replicaState
        updatedState.observingState = newState
        await updateState(updatedState)

        guard
            newState.activeObserverIds.count > previousState.activeObserverIds.count,
            settings.revalidateOnActiveObserverAdded
        else {
            return
        }

        await revalidate()
    }

    private func setLoadingStateAndLoadData(skipLoadingIfFresh: Bool) async {
        guard !replicaState.loading, !(skipLoadingIfFresh && replicaState.hasFreshData) else {
            return
        }

        var updatedState = replicaState
        updatedState.loading = true
        updatedState.error = nil

        await updateState(updatedState)

        loadingTask = Task { [weak self] in await self?.loadData() }
    }

    private func loadData() async {
        Task { @MUNLogger in
            MUNLogger.sharedLoggable?.log(type: .debug, "🔄 \(name) \(#function)")
        }

        do {
            let data: T

            if let storage, let dataFromStorage = try await storage.read() {
                data = dataFromStorage
            } else {
                data = try await dataFetcher()

                if let storage = storage {
                    try await storage.write(data: data)
                }
            }

            let replicaData = ReplicaData(value: data, isFresh: true, changingDate: .now)

            var updatedState = replicaState
            updatedState.loading = false
            updatedState.data = replicaData
            updatedState.error = nil

            await updateState(updatedState)

            let staleTime = settings.staleTime
            guard staleTime < .infinity else {
                return
            }

            staleTask?.cancel()
            staleTask = Task { [weak self] in await self?.performDataStaling(after: staleTime) }
        } catch is CancellationError {
            return
        } catch {
            var updatedState = replicaState
            updatedState.loading = false
            updatedState.error = error

            await updateState(updatedState)
        }
    }

    private func clearData(removeFromStorage: Bool) async throws {
        var updatedState = replicaState
        updatedState.data = nil
        updatedState.error = nil
        await updateState(updatedState)

        if removeFromStorage {
            try await storage?.remove()
        }
    }

    private func updateState(_ newState: ReplicaState<T>) async {
        logStateChange(from: replicaState, to: newState)
        replicaState = newState
        observerStateStreams.forEach { $0.continuation.yield(replicaState) }
    }

    private func performDataClearing(after seconds: TimeInterval) async {
        try? await Task.sleep(for: .seconds(seconds))
        let replicaState = replicaState

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
        let replicaState = replicaState

        guard replicaState.error != nil, !replicaState.loading, case .none = replicaState.observingState.status else {
            return
        }

        await clearError()
    }

    private func performCanceling(after seconds: TimeInterval) async {
        try? await Task.sleep(for: .seconds(seconds))
        let replicaState = replicaState

        guard replicaState.loading, case .none = replicaState.observingState.status else {
            return
        }

        await cancel()
    }

    private func performDataStaling(after seconds: TimeInterval) async {
        try? await Task.sleep(for: .seconds(settings.staleTime))

        guard let data = replicaState.data, data.isFresh else {
            return
        }

        var newData = replicaState.data
        newData?.isFresh = false
        var updatedState = replicaState
        updatedState.data = newData
        await updateState(updatedState)
    }

    private func clearError() async {
        var updatedState = replicaState
        updatedState.error = nil
        await updateState(updatedState)
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
        if
            oldState.observingState.observerIds != newState.observingState.observerIds
            || oldState.observingState.activeObserverIds != newState.observingState.activeObserverIds
        {
            changes.append("observing: \(oldState.observingState) → \(newState.observingState)")
        }
        if oldState.hasFreshData != newState.hasFreshData {
            changes.append("hasFreshData: \(oldState.hasFreshData) → \(newState.hasFreshData)")
        }

        if changes.isEmpty {
            Task { @MUNLogger in
                MUNLogger.sharedLoggable?.log(type: .debug, "⚖️ \(name) \(#function): No changes in state")
            }
        } else {
            Task { @MUNLogger in
                MUNLogger.sharedLoggable?.log(
                    type: .debug,
                    "⚖️ \(name) \(#function): Changed fields:\n  " + changes.joined(separator: "\n  ")
                )
            }
        }
    }

    private func handleObserverEvent(_ event: ReplicaObserverEvent, observerId: UUID ) async {
        switch event {
        case .observerAdded:
            await handleObserverAdded(observerId: observerId)
        case .observerRemoved:
            await handleObserverRemoved(observerId: observerId)
        case .observerActivated:
            await handleObserverActivated(observerId: observerId)
        case .observerDeactivated:
            await handleObserverDeactivated(observerId: observerId)
        }
    }

    private func handleObserverAdded(observerId: UUID) async {
        [errorClearingTask, dataClearingTask, cancelTask].forEach { $0?.cancel() }

        let currentObservingState = replicaState.observingState
        let newObservingState = ReplicaObservingState(
            observerIds: currentObservingState.observerIds.union([observerId]),
            activeObserverIds: currentObservingState.activeObserverIds,
            lastObservingTime: currentObservingState.lastObservingTime
        )

        await emitObserverCountChangedIfNeeded(from: currentObservingState, to: newObservingState)
    }

    private func handleObserverRemoved(observerId: UUID) async {
        let currentObservingState = replicaState.observingState
        let isLastActive = currentObservingState.activeObserverIds.count == 1
            && currentObservingState.activeObserverIds.contains(observerId)
        let updatedlastObservingTime = isLastActive ? .timeInPast(.now) : currentObservingState.lastObservingTime
        let newObservingState = ReplicaObservingState(
            observerIds: currentObservingState.observerIds.subtracting([observerId]),
            activeObserverIds: currentObservingState.activeObserverIds.subtracting([observerId]),
            lastObservingTime: updatedlastObservingTime
        )

        await emitObserverCountChangedIfNeeded(from: currentObservingState, to: newObservingState)

        guard newObservingState.status == .none else {
            return
        }

        let cancelTime = settings.cancelTime
        if cancelTime < .infinity {
            cancelTask?.cancel()
            cancelTask = Task { [weak self] in await self?.performCanceling(after: cancelTime) }
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

    private func handleObserverActivated(observerId: UUID) async {
        let currentObservingState = replicaState.observingState
        var updatedActiveObserverIds = currentObservingState.activeObserverIds
        updatedActiveObserverIds.insert(observerId)
        let newObservingState = ReplicaObservingState(
            observerIds: currentObservingState.observerIds,
            activeObserverIds: updatedActiveObserverIds,
            lastObservingTime: .now
        )

        await emitObserverCountChangedIfNeeded(from: currentObservingState, to: newObservingState)
    }

    private func handleObserverDeactivated(observerId: UUID) async {
        let currentObservingState = replicaState.observingState
        let isLastActive = currentObservingState.activeObserverIds.count == 1
            && currentObservingState.activeObserverIds.contains(observerId)
        let updatedlastObservingTime = isLastActive ? .timeInPast(.now) : currentObservingState.lastObservingTime
        let newObservingState = ReplicaObservingState(
            observerIds: currentObservingState.observerIds,
            activeObserverIds: currentObservingState.activeObserverIds.subtracting([observerId]),
            lastObservingTime: updatedlastObservingTime
        )

        await emitObserverCountChangedIfNeeded(from: currentObservingState, to: newObservingState)
    }
}
