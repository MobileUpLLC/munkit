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
    var observingState: ObservingState
    /// Указывает, были ли запрошены данные.
    var dataRequested: Bool
    /// Указывает, происходит ли в данный момент предварительная загрузка.
    var preloading: Bool
    /// Указывает, требуется ли загрузка из хранилища.
    var loadingFromStorageRequired: Bool
    
    var hasFreshData: Bool {
        data?.isFresh ?? false
    }

    var canBeRemoved: Bool {
        data == nil &&
        error == nil &&
        !loading &&
        !dataRequested &&
        observingState.status == .none
    }

    func copy(
        loading: Bool? = nil,
        data: ReplicaData<T>? = nil,
        error: Error? = nil,
        observingState: ObservingState? = nil,
        dataRequested: Bool? = nil,
        preloading: Bool? = nil,
        loadingFromStorageRequired: Bool? = nil
    ) -> ReplicaState<T> {
        ReplicaState(
            loading: loading ?? self.loading,
            data: data ?? self.data,
            error: error ?? self.error,
            observingState: observingState ?? self.observingState,
            dataRequested: dataRequested ?? self.dataRequested,
            preloading: preloading ?? self.preloading,
            loadingFromStorageRequired: loadingFromStorageRequired ?? self.loadingFromStorageRequired
        )
    }

    static func createEmpty(hasStorage: Bool) -> ReplicaState<T> {
        let observersCountInfo = ObserversCountInfo(count: 0, activeCount: 0, previousCount: 0, previousActiveCount: 0)
        let observingState = ObservingState(
            observerIds: [],
            activeObserverIds: [],
            observingTime: .never,
            observersCountInfo: observersCountInfo
        )

        return ReplicaState(
            loading: false,
            data: nil,
            error: nil,
            observingState: observingState,
            dataRequested: false,
            preloading: false,
            loadingFromStorageRequired: hasStorage
        )
    }
}

extension ReplicaState: CustomStringConvertible {
    public var description: String {
        """
        ReplicaState:
          loading: \(loading)
          data: \(data != nil ? "present" : "absent")
          error: \(error?.localizedDescription ?? "none")
          observing: \(observingState)
          dataRequested: \(dataRequested)
          preloading: \(preloading)
          loadingFromStorageRequired: \(loadingFromStorageRequired)
          hasFreshData: \(hasFreshData)
        """
    }
}

extension ObservingState: CustomStringConvertible {
    public var description: String {
        "observers: \(observerIds.count), active: \(activeObserverIds.count), observingSince: \(observingTime)"
    }
}

