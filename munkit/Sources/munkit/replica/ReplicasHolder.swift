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
        var replica: (any SingleReplica)? = nil
        for singleReplica in singleReplicas {
            if await singleReplica.name == name {
                replica = singleReplica
                break
            }
        }
        if let replica = replica as? any SingleReplica<T> {
            return replica
        }

        let newReplica = SingleReplicaImplementation(
            name: name,
            settings: settings,
            storage: storage,
            fetcher: fetcher
        )

        singleReplicas.append(newReplica)

        return newReplica
    }
}

