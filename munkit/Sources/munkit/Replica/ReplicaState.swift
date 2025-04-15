//
//  ReplicaState.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

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
        let observingState = ObservingState(observerIds: [], activeObserverIds: [], observingTime: .never)

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

    func toLoadable() -> Loadable<T> {
        return Loadable(
            loading: loading,
            data: data?.valueWithOptimisticUpdates
        )
    }
}

class Loadable<T> {
    var loading: Bool
    var data: T?
    // TO DO - добавить ошибку

    init(loading: Bool = false, data: T? = nil) {
        self.loading = loading
        self.data = data
    }
}

//extension Loadable {
//    func mapData<R>(transform: (T) -> R) -> Loadable<R> {
//        return Loadable<R>(
//            loading: loading,
//            data: data.map(transform),
//            error: error
//        )
//    }
//}
