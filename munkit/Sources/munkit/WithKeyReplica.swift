//
//  WithKeyReplica.swift
//  munkit
//
//  Created by Natalia Luzyanina on 17.04.2025.
//

import Foundation

enum MissingKeyError: Error {
    case missingKey
}

actor WithKeyReplica<K: Sendable & Hashable, T: Sendable>: Replica {
    private let keyedReplica: any KeyedReplica<K, T>
    private let keyStream: AsyncStream<K?>

    init(keyedReplica: any KeyedReplica<K, T>, keyStream: AsyncStream<K?>) {
        self.keyedReplica = keyedReplica
        self.keyStream = keyStream
    }

    func observe(activityStream: AsyncStream<Bool>) async -> any ReplicaObserver<T> {
        await keyedReplica.observe(activityStream: activityStream, key: keyStream)
    }

    func refresh() async {
        guard let key = await currentKey() else { return }
        await keyedReplica.refresh(key: key)
    }

    func revalidate() async {
        guard let key = await currentKey() else { return }
        await keyedReplica.revalidate(key: key)
    }

    func fetchData(forceRefresh: Bool) async throws -> T {
        guard let key = await currentKey() else {
            throw MissingKeyError.missingKey
        }
        return try await keyedReplica.getData(key: key, forceRefresh: forceRefresh)
    }

    private func currentKey() async -> K? {
        var lastKey: K?
        for await key in keyStream {
            lastKey = key
        }
        return lastKey
    }
}
