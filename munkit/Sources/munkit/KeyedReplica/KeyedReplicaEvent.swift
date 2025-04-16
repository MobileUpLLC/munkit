//
//  KeyedReplicaEvent.swift
//  munkit
//
//  Created by Natalia Luzyanina on 16.04.2025.
//

import Foundation

public enum KeyedReplicaEvent<K: Hashable & Sendable, T: Sendable>: Sendable {
    case replicaCreated(key: K, replica: any PhysicalReplica<T>)
    case replicaRemoved(key: K, replicaId: String)
    case replicaObserverCountChanged(replicaWithObserversCount: Int, replicaWithActiveObserversCount: Int)
}
