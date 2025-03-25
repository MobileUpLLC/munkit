import Foundation

public struct ReplicaState<T: Sendable>: Sendable {
    /// Указывает, загружаются ли данные в данный момент.
    var loading: Bool
    /// Содержит загруженные данные, если они доступны.
    var data: ReplicaData<T>?
    /// Представляет ошибку, произошедшую во время загрузки.
    var error: LoadingError?
    /// Состояние наблюдения.
    var observingState: ObservingState
    /// Указывает, были ли запрошены данные.
    var dataRequested: Bool
    /// Указывает, происходит ли в данный момент предварительная загрузка.
    var preloading: Bool
    /// Указывает, требуется ли загрузка из хранилища.
    var loadingFromStorageRequired: Bool
    /// Вычисляемое свойство для проверки свежести данных.
    var hasFreshData: Bool {
        return data?.isFresh == true
    }

    static func createEmpty(hasStorage: Bool) -> ReplicaState<T> {
        return ReplicaState(
            loading: false,
            data: nil,
            error: nil,
            observingState: ObservingState(),
            dataRequested: false,
            preloading: false,
            loadingFromStorageRequired: hasStorage
        )
    }

    func getLoadable() -> LoadableReplicaState<T> {
        return LoadableReplicaState(
            loading: loading,
            data: data?.value,
            error: error.map { CombinedLoadingError(errors: [$0]) }
        )
    }

    /// Метод для создания копии состояния с возможностью изменения некоторых свойств.
    func copy(
        loading: Bool? = nil,
        data: ReplicaData<T>? = nil,
        error: LoadingError? = nil,
        observingState: ObservingState? = nil,
        dataRequested: Bool? = nil,
        preloading: Bool? = nil,
        loadingFromStorageRequired: Bool? = nil
    ) -> ReplicaState {
        return ReplicaState(
            loading: loading ?? self.loading,
            data: data ?? self.data,
            error: error ?? self.error,
            observingState: observingState ?? self.observingState,
            dataRequested: dataRequested ?? self.dataRequested,
            preloading: preloading ?? self.preloading,
            loadingFromStorageRequired: loadingFromStorageRequired ?? self.loadingFromStorageRequired
        )
    }
}
