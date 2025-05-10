//
//  ReplicaClient.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 03.04.2025.
//

import Foundation

public actor ReplicasHolder {
    private var singleReplicas: [any SingleReplica] = []

    public static let shared = ReplicasHolder()
    
    private init() {}

    public func getReplica<T: Sendable>(
        name: String,
        settings: ReplicaSettings,
        storage: (any ReplicaStorage<T>)?,
        fetcher: @Sendable @escaping () async throws -> T
    ) async -> any SingleReplica<T> {
        if let replica = await findReplica(by: name) as? any SingleReplica<T> {
            return replica
        }

        let replica = SingleReplicaImplementation(
            name: name,
            settings: settings,
            storage: storage,
            fetcher: fetcher
        )

        singleReplicas.append(replica)

        return replica
    }

    private func findReplica(by name: String) async -> (any SingleReplica)? {
        for replica in singleReplicas {
            if await replica.name == name {
                return replica
            }
        }
        return nil
    }
}

