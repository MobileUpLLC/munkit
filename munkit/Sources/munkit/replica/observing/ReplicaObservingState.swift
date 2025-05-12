//
//  ObservingState.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

/// Contains information about the observers of a replica.
public struct ReplicaObservingState: Sendable {
    let observerIds: Set<UUID>
    let activeObserverIds: Set<UUID>
    let lastObservingTime: ReplicaLastObservingTime

    /// The current observation status based on the number of observers.
    var status: ObservingStatus {
        if activeObserverIds.count > 0 {
            return .active
        } else if observerIds.count > 0 {
            return .inactive
        } else {
            return .none
        }
    }
}

/// Represents the status of observers for a replica.
enum ObservingStatus {
    /// No observers
    case none
    /// There are inactive observers
    case inactive
    /// There are active observers
    case active
}

/// Represents the time of the last observation of a replica.
enum ReplicaLastObservingTime {
    case never
    case timeInPast(Date)
    case now
}

extension ReplicaObservingState: CustomStringConvertible {
    public var description: String {
        "observers: \(observerIds.count), active: \(activeObserverIds.count), observingSince: \(lastObservingTime)"
    }
}
