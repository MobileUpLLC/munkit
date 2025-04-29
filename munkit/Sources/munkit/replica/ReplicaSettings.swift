//
//  ReplicaSettings.swift
//  munkit
//
//  Created by Ilia Chub on 28.04.2025.
//

import Foundation

/// Configures behavior of a replica.
public struct ReplicaSettings: Sendable {
    /// Specifies how quickly fetched data will become stale
    let staleTime: TimeInterval

    /// Specifies how quickly data will be cleared when there is no observers
    let clearTime: TimeInterval

    /// Specifies how quickly error will be cleared when there is no observers
    let clearErrorTime: TimeInterval

    /// Specifies how quickly request will be canceled when there is no observers
    let cancelTime: TimeInterval

    public init(
        staleTime: TimeInterval,
        clearTime: TimeInterval,
        clearErrorTime: TimeInterval,
        cancelTime: TimeInterval
    ) {
        self.staleTime = staleTime
        self.clearTime = clearTime
        self.clearErrorTime = clearErrorTime
        self.cancelTime = cancelTime
    }
}
