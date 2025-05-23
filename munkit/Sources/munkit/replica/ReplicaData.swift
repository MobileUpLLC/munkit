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
