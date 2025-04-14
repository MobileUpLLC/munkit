//
//  ReplicaData.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

public struct ReplicaData<T>: Sendable where T: Sendable {
    public var value: T
    var isFresh: Bool
    var changingDate: Date
    var optimisticUpdates: [any OptimisticUpdate<T>]

    var valueWithOptimisticUpdates: T {
        optimisticUpdates.reduce(value) { currentData, update in
            update.apply(to: currentData)
        }
    }

    init(value: T, isFresh: Bool, changingDate: Date, optimisticUpdates: [any OptimisticUpdate<T>] = []) {
        self.value = value
        self.isFresh = isFresh
        self.changingDate = changingDate
        self.optimisticUpdates = optimisticUpdates
    }
}

public protocol OptimisticUpdate<T>: Sendable, AnyObject {
    associatedtype T

    func apply(to data: T) -> T
}
