//
//  ReplicaState.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

public struct ReplicaState<T>: Sendable where T: Sendable {
    /// Indicates whether data is currently being loaded.
    public var loading: Bool
    /// Contains the loaded data, if available.
    public var data: ReplicaData<T>?
    /// Represents an error that occurred during loading.
    public var error: Error?
    /// The observation state.
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
