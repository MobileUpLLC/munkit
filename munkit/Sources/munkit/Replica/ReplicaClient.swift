//
//  ReplicaClient.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 03.04.2025.
//

import Foundation

public actor ReplicaClient {
    private var replicas: [any PhysicalReplica] = []
    private var keyedReplicas: [any KeyedPhysicalReplica] = []

    public static let shared = ReplicaClient()

    private init() {}

    public func createReplica<T: Sendable>(
        name: String,
        storage: (any Storage<T>)?,
        fetcher: @Sendable @escaping () async throws -> T
    ) async -> any PhysicalReplica<T> {
        if let replica = await findReplica(by: name) as? any PhysicalReplica<T> {
            return replica
        }

        let replica = PhysicalReplicaImplementation(
            name: name,
            storage: storage,
            fetcher: fetcher
        )

        if replicas.isEmpty {
            replicas.append(replica)
        }
        return replica
    }



    func createKeyedReplica<K: Sendable & Hashable, T: Sendable>(
        name: String,
        childName: @Sendable @escaping (K) -> String,
        fetcher: @Sendable @escaping (K)  async throws -> T
    ) async -> any KeyedPhysicalReplica<K, T> {

        if let replica = await findKeyedReplica(by: name) as? any KeyedPhysicalReplica<K, T> {
            return replica
        }

        let replicaFactory: @Sendable (K) async -> any PhysicalReplica<T> = { (key: K) in
            let replica = PhysicalReplicaImplementation(
                name: childName(key),
                storage: nil,
                fetcher: { try await fetcher(key) }
            ) as any PhysicalReplica<T>

            return replica
        }

        let keyedReplica = KeyedPhysicalReplicaImplementation<K, T>(
            name: name,
            replicaFactory: replicaFactory
        )

        if keyedReplicas.isEmpty {
            keyedReplicas.append(keyedReplica)
        }
        return keyedReplica
    }

    private func findReplica(by name: String) async -> (any PhysicalReplica)? {
        for replica in replicas {
            if await replica.name == name {
                return replica
            }
        }
        return nil
    }

    private func findKeyedReplica(by name: String) async -> (any KeyedPhysicalReplica)? {
        for replica in keyedReplicas {
            if await replica.name == name {
                return replica
            }
        }
        return nil
    }
}
