import Foundation

public struct ReplicaState<T>: Sendable where T: Sendable {
    /// Указывает, загружаются ли данные в данный момент.
    let loading: Bool
    /// Содержит загруженные данные, если они доступны.
    let data: ReplicaData<T>?
    /// Представляет ошибку, произошедшую во время загрузки.
    let error: Error?
    /// Состояние наблюдения.
    var observingState: ObservingState
    /// Указывает, были ли запрошены данные.
    let dataRequested: Bool
    /// Указывает, происходит ли в данный момент предварительная загрузка.
    let preloading: Bool
    /// Указывает, требуется ли загрузка из хранилища.
    let loadingFromStorageRequired: Bool
}
