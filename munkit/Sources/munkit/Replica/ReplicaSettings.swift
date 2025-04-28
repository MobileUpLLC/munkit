//
//  ReplicaSettings.swift
//  munkit
//
//  Created by Ilia Chub on 28.04.2025.
//

import Foundation

/// Configures behavior of a replica.
struct ReplicaSettings {
    /// Specifies how quickly fetched data will become stale (nil means never).
    let staleTime: TimeInterval?

    /// Specifies how quickly data will be cleared when there are no observers (nil means never).
    let clearTime: TimeInterval?

    /// Specifies how quickly an error will be cleared when there are no observers (nil means never).
    let clearErrorTime: TimeInterval?

    /// Specifies how quickly a request will be canceled when there are no observers (nil means never).
    let cancelTime: TimeInterval?

    /// Specifies if stale data will be refreshed when an active observer is added.
    let revalidateOnActiveObserverAdded: Bool

    /// Specifies if stale data will be refreshed when a network connection is established and a replica has an active observer.
    /// Note: NetworkConnectivityProvider has to be added to ReplicaClient.
    let revalidateOnNetworkConnection: Bool

    init(
        staleTime: TimeInterval? = nil,
        clearTime: TimeInterval? = nil,
        clearErrorTime: TimeInterval? = 0.25,
        cancelTime: TimeInterval? = 0.25,
        revalidateOnActiveObserverAdded: Bool = true,
        revalidateOnNetworkConnection: Bool = true
    ) {
        self.staleTime = staleTime
        self.clearTime = clearTime
        self.clearErrorTime = clearErrorTime
        self.cancelTime = cancelTime
        self.revalidateOnActiveObserverAdded = revalidateOnActiveObserverAdded
        self.revalidateOnNetworkConnection = revalidateOnNetworkConnection
    }

    /// Settings for a replica with no automatic behavior.
    static let withoutBehaviour = ReplicaSettings(
        staleTime: nil,
        clearTime: nil,
        clearErrorTime: nil,
        cancelTime: nil,
        revalidateOnActiveObserverAdded: false,
        revalidateOnNetworkConnection: false
    )
}
