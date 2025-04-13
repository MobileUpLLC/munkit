//
//  PhysicalReplica.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 10.04.2025.
//

import Foundation

public protocol PhysicalReplica<T>: Replica where T: Sendable {
    var name: String { get }

    init(id: UUID, storage: (any Storage<T>)?, fetcher: @escaping Fetcher<T>, name: String)

    func clear(invalidationMode: InvalidationMode, removeFromStorage: Bool) async
    func clearError() async
    func invalidate(mode: InvalidationMode) async
    func makeFresh() async
}

public extension PhysicalReplica {
    public func clear(invalidationMode: InvalidationMode = .dontRefresh, removeFromStorage: Bool = true) async {
        await clear(invalidationMode: invalidationMode, removeFromStorage: removeFromStorage)
    }

    public func invalidate(mode: InvalidationMode = .refreshIfHasObservers) async {
        await invalidate(mode: mode)
    }
}

