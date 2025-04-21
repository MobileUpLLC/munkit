//
//  ReplicaObserver.swift
//  munkit
//
//  Created by Natalia Luzyanina on 18.04.2025.
//

import Foundation

public protocol ReplicaObserver<T>: Actor where T: Sendable {
    associatedtype T: Sendable

    var stateStream: AsyncStream<ReplicaState<T>> { get }

    func stopObserving() async
}
