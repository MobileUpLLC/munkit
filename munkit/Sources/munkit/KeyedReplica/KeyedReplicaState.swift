//
//  KeyedReplicaState.swift
//  munkit
//
//  Created by Natalia Luzyanina on 16.04.2025.
//

import Foundation

public struct KeyedReplicaState: Sendable {
    public var replicaCount: Int
    public let replicaWithObserversCount: Int
    public let replicaWithActiveObserversCount: Int

    public static let empty = KeyedReplicaState(
        replicaCount: 0,
        replicaWithObserversCount: 0,
        replicaWithActiveObserversCount: 0
    )

    public init(
        replicaCount: Int,
        replicaWithObserversCount: Int,
        replicaWithActiveObserversCount: Int
    ) {
        self.replicaCount = replicaCount
        self.replicaWithObserversCount = replicaWithObserversCount
        self.replicaWithActiveObserversCount = replicaWithActiveObserversCount
    }
}
