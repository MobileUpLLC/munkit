//
//  PhysicalReplica.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 10.04.2025.
//

import Foundation

public protocol PhysicalReplica<T>: Replica where T: Sendable {
    var name: String { get }
    var settings: ReplicaSettings { get }

    init(
        name: String,
        settings: ReplicaSettings,
        storage: (any Storage<T>)?,
        fetcher: @Sendable @escaping () async throws -> T
    )
}
