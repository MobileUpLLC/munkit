//
//  File.swift
//  NetworkService
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
        fetcher: @escaping Fetcher<T>
    ) -> any PhysicalReplica<T> {
//        if let replica = replicas.first(where: { $0.name == name })  {
//            return replica
//        }

        let replica = PhysicalReplicaImpl(
            id: UUID(),
            storage: storage,
            fetcher: fetcher,
            name: name
        )

        if replicas.isEmpty {
            replicas.append(replica)
        }
        return replica
    }
}

