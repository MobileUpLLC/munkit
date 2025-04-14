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

    func withOptimisticUpdate(
       update: any OptimisticUpdate<T>,
       onSuccess: (@Sendable () async -> Void)?,
       onError: (@Sendable (Error) async -> Void)?,
       onCanceled: (@Sendable () async -> Void)?,
       onFinished: (@Sendable () async -> Void)?,
       block: @escaping @Sendable () async throws -> T
   ) async throws -> T
}

public extension PhysicalReplica {
    func clear(invalidationMode: InvalidationMode = .dontRefresh, removeFromStorage: Bool = true) async {
        await clear(invalidationMode: invalidationMode, removeFromStorage: removeFromStorage)
    }

    func invalidate(mode: InvalidationMode = .refreshIfHasObservers) async {
        await invalidate(mode: mode)
    }

    func withOptimisticUpdate(
           update: any OptimisticUpdate<T>,
           onSuccess: (@Sendable () async -> Void)? = nil,
           onError: (@Sendable (Error) async -> Void)? = nil,
           onCanceled: (@Sendable () async -> Void)? = nil,
           onFinished: (@Sendable () async -> Void)? = nil,
           block: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        try await withOptimisticUpdate(
            update: update,
            onSuccess: onSuccess,
            onError: onError,
            onCanceled: onCanceled,
            onFinished: onFinished,
            block: block
        )
    }
}

