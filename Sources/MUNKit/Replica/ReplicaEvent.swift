//
//  ReplicaEvent.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

/// Событие, произошедшее в реплике.
public enum ReplicaEvent<T>: Sendable where T: Sendable  {
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
}

public enum LoadingFinished<T>: Sendable where T: Sendable {
    /// Успешная загрузка с данными.
    case success(data: ReplicaData<T>)
    /// Загрузка отменена.
    case canceled
    /// Ошибка загрузки.
    case error(Error)
}

public enum LoadingEvent<T>: Sendable where T: Sendable {
    /// Начало загрузки.
    case loadingStarted(dataRequested: Bool, preloading: Bool)
    /// Данные загружены из хранилища.
    case dataFromStorageLoaded(data: ReplicaData<T>)
    /// Результат завершения загрузки.
    case loadingFinished(LoadingFinished<T>)
}

public enum FreshnessEvent: Sendable {
    /// Данные стали свежими.
    case freshened
    /// Данные устарели.
    case becameStale
}

public struct ObserversCountInfo: Sendable {
    let count: Int
    let activeCount: Int
    let previousCount: Int
    let previousActiveCount: Int
}
