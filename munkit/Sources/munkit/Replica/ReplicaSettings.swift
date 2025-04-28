//
//  ReplicaSettings.swift
//  munkit
//
//  Created by Ilia Chub on 28.04.2025.
//

import Foundation

/// Configures behavior of a replica.
public struct ReplicaSettings: Sendable {
    /// Specifies how quickly fetched data will become stale (nil means never).
    let staleTime: TimeInterval

    public init(staleTime: TimeInterval) {
        self.staleTime = staleTime
    }
}
