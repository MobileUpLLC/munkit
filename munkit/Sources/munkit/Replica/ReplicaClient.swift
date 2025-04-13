//
//  ReplicaClient.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 03.04.2025.
//

import Foundation

public actor ReplicaClient {
    private var replicas: [any PhysicalReplica] = []

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
            storage: storage,
            fetcher: fetcher,
            name: name
        )

        if replicas.isEmpty {
            replicas.append(replica)
        }
        return replica
    }

    private func findReplica(by name: String) async -> (any PhysicalReplica)? {
        for replica in replicas {
            if await replica.name == name {
                return replica
            }
        }
        return nil
    }
}

