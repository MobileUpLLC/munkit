//
//  ReplicaEvent.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

/// Событие, произошедшее в реплике.
enum ReplicaEvent<T>: Sendable where T: Sendable  {
    /// События, связанные с загрузкой.
    case loading(LoadingEvent<T>)
    /// События, связанные со свежестью данных.
    case freshness(FreshnessEvent)
    /// Данные очищены.
    case cleared
    /// Ошибка очищена.
    case clearedError
    /// Изменение количества наблюдателей.
    case observerCountChanged(ObservingState)
    /// События изменения данных
    case changing(ChangingDataEvent<T>)
    /// События оптимистичных обновлений
    case optimisticUpdates(OptimisticUpdatesEvent<T>)
}

enum OptimisticUpdatesEvent<T>: Sendable where T: Sendable {
    /// Добавляет обновление в список ожидающих обновлений
    case begin(data: ReplicaData<T>)
    /// Подтверждает оптимистичное обновление, применяя его к данным и сохраняя в хранилище.
    case commit(data: ReplicaData<T>)
    /// Откатывает оптимистичное обновление, удаляя его из списка ожидающих обновлений.
    case rollback(data: ReplicaData<T>)
}

enum ChangingDataEvent<T>: Sendable where T: Sendable {
    /// Замена текущих данных на новые
    case dataSetting(data: ReplicaData<T>)
    /// Модификация текущих данных
    case dataMutating(data: ReplicaData<T>)
}

enum LoadingFinished<T>: Sendable where T: Sendable {
    /// Успешная загрузка с данными.
    case success(data: ReplicaData<T>)
    /// Загрузка отменена.
    case canceled
    /// Ошибка загрузки.
    case error(Error)
}

enum LoadingEvent<T>: Sendable where T: Sendable {
    /// Начало загрузки.
    case loadingStarted(dataRequested: Bool, preloading: Bool)
    /// Данные загружены из хранилища.
    case dataFromStorageLoaded(data: ReplicaData<T>)
    /// Результат завершения загрузки.
    case loadingFinished(LoadingFinished<T>)
}

enum FreshnessEvent: Sendable {
    /// Данные стали свежими.
    case freshened
    /// Данные устарели.
    case becameStale
}

struct ObserversCountInfo: Sendable {
    let count: Int
    let activeCount: Int
    let previousCount: Int
    let previousActiveCount: Int
}

extension ReplicaEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case .loading(let event): "Loading: \(event)"
        case .freshness(let event): "Freshness: \(event)"
        case .cleared: "Data cleared"
        case .clearedError: "Error cleared"
        case .observerCountChanged(let state): "Observers changed: \(state)"
        case .changing(let event): "Data change: \(event)"
        case .optimisticUpdates(let event): "Optimistic update: \(event)"
        }
    }
}

extension OptimisticUpdatesEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case .begin: "Began update"
        case .commit: "Committed update"
        case .rollback: "Rolled back update"
        }
    }
}

extension ChangingDataEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case .dataSetting: "Data set"
        case .dataMutating: "Data mutated"
        }
    }
}

extension LoadingFinished: CustomStringConvertible {
    var description: String {
        switch self {
        case .success: "Loaded successfully"
        case .canceled: "Loading canceled"
        case .error(let error): "Loading failed: \(error)"
        }
    }
}

extension LoadingEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case .loadingStarted(let dataRequested, let preloading):
            "Started loading (dataRequested: \(dataRequested), preloading: \(preloading))"
        case .dataFromStorageLoaded: "Loaded from storage"
        case .loadingFinished(let result): "Finished: \(result)"
        }
    }
}

extension FreshnessEvent: CustomStringConvertible {
    var description: String {
        switch self {
        case .freshened: "Data freshened"
        case .becameStale: "Data stale"
        }
    }
}

extension ObserversCountInfo: CustomStringConvertible {
    var description: String {
        "count: \(count), active: \(activeCount) (prev: \(previousCount), prevActive: \(previousActiveCount))"
    }
}
