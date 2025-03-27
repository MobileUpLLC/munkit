import Foundation

public struct ReplicaState<T> {
    /// Указывает, загружаются ли данные в данный момент.
    var loading: Bool
    /// Содержит загруженные данные, если они доступны.
    var data: ReplicaData<T>?
    /// Представляет ошибку, произошедшую во время загрузки.
    var error: Error?
    /// Состояние наблюдения.
    var observingState: ObservingState
    /// Указывает, были ли запрошены данные.
    var dataRequested: Bool
    /// Указывает, происходит ли в данный момент предварительная загрузка.
    var preloading: Bool
    /// Указывает, требуется ли загрузка из хранилища.
    var loadingFromStorageRequired: Bool


    static func createEmpty(hasStorage: Bool) -> ReplicaState<T> {
        let observingState = ObservingState(
            observerIds: Set<UUID>(),
            activeObserverIds: Set<UUID>(),
            observingTime: .never
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
