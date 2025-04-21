//
//  KeyedReplica.swift
//  munkit
//
//  Created by Natalia Luzyanina on 16.04.2025.
//

public protocol KeyedReplica<K, T>: Actor where T: Sendable, K: Hashable & Sendable {
    associatedtype T: Sendable
    associatedtype K: Hashable & Sendable

    /// Starts observing a keyed replica. Returns a ReplicaObserver that provides access to replica state and error events.
    /// В оригинале метод возвращает ReplicaObserver<T>
    func observe(activityStream: AsyncStream<Bool>, key: AsyncStream<K?>) async -> any ReplicaObserver<T>

    /// Loads fresh data from the network for a given key.
    func refresh(key: K) async

    /// Loads fresh data from the network for a given key if the data is stale.
    func revalidate(key: K) async

    /// Loads and returns data for a given key. Throws an error if the operation fails.
    /// Never returns stale data. Makes a network request if data is stale.
    func getData(key: K, forceRefresh: Bool) async throws -> T
}

public extension KeyedReplica {
    public func withKey(_ key: K) -> any Replica<T> {
        let keyStream = AsyncStream<K?> { continuation in
            continuation.yield(key)
            continuation.finish()
        }
        return WithKeyReplica(keyedReplica: self, keyStream: keyStream)
    }

    public func withKey(keyStream: AsyncStream<K?>) -> any Replica<T> {
        return WithKeyReplica(keyedReplica: self, keyStream: keyStream)
    }
}
