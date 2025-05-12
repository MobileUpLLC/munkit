//
//  ReplicaState.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

public struct ReplicaState<T>: Sendable where T: Sendable {
    /// Указывает, загружаются ли данные в данный момент.
    public var loading: Bool
    /// Содержит загруженные данные, если они доступны.
    public var data: ReplicaData<T>?
    /// Представляет ошибку, произошедшую во время загрузки.
    public var error: Error?
    /// Состояние наблюдения.
    var observingState: ReplicaObservingState
    
    public var hasFreshData: Bool { data?.isFresh ?? false }
}

extension ReplicaState: CustomStringConvertible {
    public var description: String {
        """
        ReplicaState:
          loading: \(loading)
          data: \(data != nil ? "present" : "absent")
          error: \(error?.localizedDescription ?? "none")
          observing: \(observingState)
          hasFreshData: \(hasFreshData)
        """
    }
}
