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
}
