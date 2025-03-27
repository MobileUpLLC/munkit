import Foundation

/// Событие, произошедшее в реплике.
public enum ReplicaEvent<T> {
    /// События, связанные с загрузкой.
    case loading(LoadingEvent<T>)
    /// События, связанные со свежестью данных.
    case freshness(FreshnessEvent)
    /// Данные и ошибки очищены.
    case cleared
    /// Изменение количества наблюдателей.
    case observerCountChanged(ObserversCountInfo)
}

public enum LoadingFinished<T> {
    /// Успешная загрузка с данными.
    case success(data: T)
    /// Загрузка отменена.
    case canceled
    /// Ошибка загрузки.
    case error(Error)
}

public enum LoadingEvent<T> {
    /// Начало загрузки.
    case loadingStarted
    /// Данные загружены из хранилища.
    case dataFromStorageLoaded(data: T)
    /// Результат завершения загрузки.
    case loadingFinished(LoadingFinished<T>)
}

public enum FreshnessEvent {
    /// Данные стали свежими.
    case freshened
    /// Данные устарели.
    case becameStale
}

public struct ObserversCountInfo {
    let count: Int
    let activeCount: Int
    let previousCount: Int
    let previousActiveCount: Int
}
