//
//  PhysicalReplica.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 10.04.2025.
//

import Foundation

public protocol PhysicalReplica<T>: Replica where T: Sendable {
    var name: String { get }

    init(storage: (any Storage<T>)?, fetcher: @Sendable @escaping () async throws -> T, name: String)

    func clear(invalidationMode: InvalidationMode, removeFromStorage: Bool) async
    func clearError() async
    func invalidate(mode: InvalidationMode) async
    func makeFresh() async
    func setData(data: T) async
    func mutataData(transform: @escaping (T) -> T)
}

public extension PhysicalReplica {
    func clear(invalidationMode: InvalidationMode = .dontRefresh, removeFromStorage: Bool = true) async {
        await clear(invalidationMode: invalidationMode, removeFromStorage: removeFromStorage)
    }

    func invalidate(mode: InvalidationMode = .refreshIfHasObservers) async {
        await invalidate(mode: mode)
    }
}

