//
//  Replica.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

/// Protocol for a base replica with minimal API.
public protocol Replica<T>: Actor where T: Sendable {
    associatedtype T: Sendable

    /// Starts observing the replica's state.
    func observe(activityStream: AsyncStream<Bool>) async -> any ReplicaObserver<T>

    /// Fetches fresh data from the network.
    /// - Note: Does not trigger a new request if one is already in progress.
    func refresh() async

    /// Fetches fresh data from the network if the current data is stale.
    /// - Note: Does not trigger a new request if one is already in progress.
    func revalidate() async

    /// Fetches and returns the data.
    /// - Parameter forceRefresh: Forces a network request even if data is fresh.
    /// - Returns: Fresh data.
    /// - Throws: An error if the fetch fails.
    /// - Note: Always returns fresh data, fetching if necessary.
    func fetchData(forceRefresh: Bool) async throws -> T
}
