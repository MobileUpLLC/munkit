//
//  KeyedReplicaImplementation.swift
//  munkit
//
//  Created by Ilia Chub on 12.05.2025.
//

import Foundation

actor KeyedReplicaImplementation<K: Hashable & Sendable, T: Sendable>: KeyedReplica {
    var name: String

    private let settings: KeyedReplicaSettings<K, T>
    private let fetcher: @Sendable (K) async throws -> T
    private let replicaState: KeyedReplicaState
    private let childNameFacroty: @Sendable (K) -> String
    private let childSettingsFactory: @Sendable (K) -> ReplicaSettings

    private var replicas: [K: any SingleReplica<T>] = [:]
    
    init(
        name: String,
        settings: KeyedReplicaSettings<K, T>,
        childNameFacroty: @Sendable @escaping (K) -> String,
        childSettingsFactory: @Sendable @escaping (K) -> ReplicaSettings,
        fetcher: @escaping @Sendable (K) async throws -> T
    ) {
        self.name = name
        self.settings = settings
        self.fetcher = fetcher
        self.replicaState = KeyedReplicaState(
            replicaCount: 0,
            replicaWithObserversCount: 0,
            replicaWithActiveObserversCount: 0
        )
        self.childNameFacroty = childNameFacroty
        self.childSettingsFactory = childSettingsFactory
    }

    func observe(activityStream: AsyncStream<Bool>, keyStream: AsyncStream<K>) async -> KeyedReplicaObserver<K, T> {
        return KeyedReplicaObserver<K, T>(
            activityStream: activityStream,
            keyStream: keyStream,
            replicaProvider: getOrCreateReplica
        )
    }

    func refresh(key: K) async {
        await getOrCreateReplica(key).refresh()
    }

    func revalidate(key: K) async {
        await getOrCreateReplica(key).revalidate()
    }

    private func getOrCreateReplica(_ key: K) async -> any SingleReplica<T> {
        if let replica = replicas[key] {
            return replica
        }

        var replicasCurrentValueByKey: [(K, ReplicaState<T>)] = []
        for replica in replicas {
            replicasCurrentValueByKey.append(await (replica.key, replica.value.currentState))
        }

        if
            replicas.count == settings.maxCount,
            let keyForRemoving = replicasCurrentValueByKey.sorted(
                by: settings.childRemovingPolicy.comparator
            ).first?.0
        {
            MUNLogger.shared?
                .logDebug(
                    "🕸️🧙☠️ Removing replica for key \(keyForRemoving) with policy: \(settings.childRemovingPolicy)"
                )
            replicas.removeValue(forKey: keyForRemoving)
        }

        MUNLogger.shared?.logDebug("🕸️🧙🆕 Creating replica for key \(key)")

        let replica = await ReplicasHolder.shared.getSingleReplica(
            name: childNameFacroty(key),
            settings: childSettingsFactory(key),
            storage: nil,
            fetcher: { try await self.fetcher(key) },
        )

        replicas[key] = replica
        return replica
    }
}
