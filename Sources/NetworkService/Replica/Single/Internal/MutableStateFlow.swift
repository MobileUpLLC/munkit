//
//  File.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 25.03.2025.
//

import Foundation

/// Поток состояния с текущим значением и возможностью подписки.
actor MutableStateFlow<T: Sendable> {
    private var _value: ReplicaState<T>
    private let stream: AsyncStream<ReplicaState<T>>
    private let continuation: AsyncStream<ReplicaState<T>>.Continuation

    var value: ReplicaState<T> {
        get { _value }
        set { _value = newValue; continuation.yield(newValue) }
    }

    var values: AsyncStream<ReplicaState<T>> { stream }

    init(_ value: ReplicaState<T>) {
        self._value = value
        (stream, continuation) = AsyncStream.makeStream(of: ReplicaState<T>.self)
        continuation.yield(value)
    }
}

/// Поток событий без хранения текущего значения.
final class MutableSharedFlow<T> {
    private let stream: AsyncStream<T>
    private let continuation: AsyncStream<T>.Continuation

    init() {
        (stream, continuation) = AsyncStream.makeStream(of: T.self)
    }

    func emit(_ value: T) async {
        continuation.yield(value)
    }

    var values: AsyncStream<T> { stream }
}
