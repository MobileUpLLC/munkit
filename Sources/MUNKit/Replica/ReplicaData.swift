//
//  ReplicaData.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

/// Данные, хранимые в реплике.
public struct ReplicaData<T>: Sendable where T: Sendable {
    public let value: T
    var isFresh: Bool
    let changingDate: Date
    let optimisticUpdates: [OptimisticUpdate<T>]

    var valueWithOptimisticUpdates: T {
        optimisticUpdates.applyAll(to: value)
    }

    init(value: T, isFresh: Bool, changingDate: Date, optimisticUpdates: [OptimisticUpdate<T>] = []) {
        self.value = value
        self.isFresh = isFresh
        self.changingDate = changingDate
        self.optimisticUpdates = optimisticUpdates
    }
}

// TO DO: Implement OptimisticUpdate
struct OptimisticUpdate<T> {
    func apply(to value: T) -> T { value }
}

extension Array {
    func applyAll<T>(to value: T) -> T where Element == OptimisticUpdate<T> {
        reduce(value) { $1.apply(to: $0) }
    }
}
