import Foundation

public struct ReplicaState<T>: Sendable where T: Sendable {
    /// Указывает, загружаются ли данные в данный момент.
    public let loading: Bool
    /// Содержит загруженные данные, если они доступны.
    public let data: ReplicaData<T>?
    /// Представляет ошибку, произошедшую во время загрузки.
    public let error: Error?
    /// Состояние наблюдения.
    var observingState: ObservingState
    /// Указывает, были ли запрошены данные.
    let dataRequested: Bool
    /// Указывает, происходит ли в данный момент предварительная загрузка.
    let preloading: Bool
    /// Указывает, требуется ли загрузка из хранилища.
    let loadingFromStorageRequired: Bool
    
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
}
