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

    init(value: T, isFresh: Bool, changingDate: Date) {
        self.value = value
        self.isFresh = isFresh
        self.changingDate = changingDate
    }
}

// Оптимистичное обновление
public final class OptimisticUpdate<T>: Sendable where T: Sendable {
    private let _apply: @Sendable (T) -> T

    public init(apply: @escaping @Sendable (T) -> T) {
        self._apply = apply
    }

    func apply(_ data: T) -> T {
        _apply(data)
    }
}
