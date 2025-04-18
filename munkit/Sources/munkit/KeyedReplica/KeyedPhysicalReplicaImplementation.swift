//
//  KeyedPhysicalReplicaImplementation.swift
//  munkit
//
//  Created by Natalia Luzyanina on 16.04.2025.
//

import Foundation

public actor KeyedPhysicalReplicaImplementation<K: Hashable & Sendable, T: Sendable>: KeyedPhysicalReplica {
    public let id: String
    public let name: String

    private let replicaFactory: @Sendable (K) async -> any PhysicalReplica<T>
    private var keyedReplicaState: KeyedReplicaState
    private var replicas: [K: any PhysicalReplica<T>] = [:]

    private var observerStateStreams: [AsyncStreamBundle<KeyedReplicaState>] = []
    public let observersControllerEventStream: AsyncStreamBundle<KeyedReplicaEvent<K, T>>
    public let eventStream: AsyncStreamBundle<KeyedReplicaEvent<K, T>>

    private let childRemovingControllerEventStream: AsyncStreamBundle<KeyedReplicaEvent<K, T>>

    private let childRemovingController: KeyedReplicaChildRemovingController<K, T>
    private let observerCountController: KeyedReplicaObserversController<K, T>

    public init(
        id: String = UUID().uuidString,
        name: String,
        replicaFactory: @escaping @Sendable (K) async -> (any PhysicalReplica<T>)
    ) {
        self.id = id
        self.name = name
        self.replicaFactory = replicaFactory

        self.eventStream = AsyncStream.makeStream(of: KeyedReplicaEvent<K, T>.self)
        self.childRemovingControllerEventStream = AsyncStream.makeStream(of: KeyedReplicaEvent<K, T>.self)

        self.keyedReplicaState = KeyedReplicaState.empty

        self.observersControllerEventStream = AsyncStream.makeStream(of: KeyedReplicaEvent<K, T>.self)

        self.observerCountController = KeyedReplicaObserversController(
            initialState: keyedReplicaState,
            eventStreamContinuation: observersControllerEventStream.continuation
        )
        self.childRemovingController = KeyedReplicaChildRemovingController(
            replicaEventStreamContinuation: childRemovingControllerEventStream.continuation
        )

        Task {
            await processEvents()
        }
    }

    private func removeReplica(key: K) async {
        let removedReplica = replicas.removeValue(forKey: key)
        guard let removedReplica else {
            return
        }
        await eventStream.continuation.yield(.replicaRemoved(key: key, replicaId: removedReplica.id))
    }

    public func observe(activityStream: AsyncStream<Bool>, key: AsyncStream<K?>) async ->
    any ReplicaObserver<T> {
        let stateStreamBundle = AsyncStream<KeyedReplicaState>.makeStream()
        observerStateStreams.append(stateStreamBundle)

        return KeyedReplicaObserver(
            activityStream: activityStream,
            keyStream: key,
            replicaProvider: { [weak self] key in
                return await self?.getOrCreateReplica(key: key)
            }
        )
    }

    public func refresh(key: K) async {
        await getOrCreateReplica(key: key).refresh()
    }

    public func revalidate(key: K) async {
        await getOrCreateReplica(key: key).revalidate()
    }

    public func getData(key: K, forceRefresh: Bool) async throws -> T {
        try await getOrCreateReplica(key: key).fetchData(forceRefresh: forceRefresh)
    }

    private func processEvents() {
        let eventStreams = [
            observersControllerEventStream.stream,
            childRemovingControllerEventStream.stream
        ]

        Task {
            await withTaskGroup(of: Void.self) { group in
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

    private func handleEvent(_ event: KeyedReplicaEvent<K, T>) {
        // TODO: 
    }

    private func getOrCreateReplica(key: K) async -> any PhysicalReplica<T> {
        if let replica = replicas[key] {
            return replica
        }

        let replica = await replicaFactory(key)
        replicas[key] = replica

        await childRemovingController.setupAutoRemoving(key: key, replica: replica)
        await observerCountController.setupObserverCounting(replica: replica)

        let newCount = replicas.count
        keyedReplicaState.replicaCount = newCount

        await updateState(keyedReplicaState)

        eventStream.continuation.yield(.replicaCreated(key: key, replica: replica))

        return replica
    }

    private func updateState(_ newState: KeyedReplicaState) async {
        print("⚖️", name, #function, newState)

        keyedReplicaState = newState

        await observerCountController.updateState(newState)

        observerStateStreams.forEach { $0.continuation.yield(keyedReplicaState) }
    }
}
