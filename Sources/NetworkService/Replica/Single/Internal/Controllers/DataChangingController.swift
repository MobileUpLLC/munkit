//
//  File.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 25.03.2025.
//

import Foundation

// Актор для управления изменением данных
actor DataChangingController<T: Sendable> {
    private let timeProvider: TimeProvider
    private var replicaState: ReplicaState<T>
    private let storage: (any Storage<T>)?

    /// Инициализирует контроллер изменения данных с заданным начальным состоянием и зависимостями.
    /// - Parameters:
    ///   - timeProvider: Провайдер текущего времени для отметки изменений.
    ///   - initialState: Начальное состояние реплики.
    ///   - storage: Опциональное хранилище для записи данных.
    init(timeProvider: TimeProvider, initialState: ReplicaState<T>, storage: (any Storage<T>)?) {
        self.timeProvider = timeProvider
        self.replicaState = initialState
        self.storage = storage
    }

    /// Устанавливает новые данные в состоянии реплики и, при необходимости, записывает их в хранилище.
    /// - Parameter data: Новые данные типа `T` для установки.
    /// - Throws: Ошибка, если запись в хранилище не удалась.
    func setData(data: T) async throws {
        var changedReplicaData: ReplicaData<T>?

        if let existingData = replicaState.data {
            changedReplicaData = existingData.copy(
                value: data,
                changingDate: timeProvider.currentTime
            )
        } else {
            changedReplicaData = ReplicaData<T>(
                value: data,
                isFresh: false,
                changingDate: timeProvider.currentTime,
                optimisticUpdates: []
            )
        }

        replicaState = replicaState.copy(data: changedReplicaData, loadingFromStorageRequired: false)

        try await storage?.write(data: data)
    }

    /// Изменяет существующие данные в состоянии реплики с помощью переданной функции преобразования.
    /// - Parameter transform: Функция, принимающая текущие данные типа `T` и возвращающая новые данные.
    /// - Throws: Ошибка, если запись в хранилище не удалась.
    func mutateData(transform: @escaping (T) -> T) async throws {
        if let data = replicaState.data {
            let newData = transform(data.value)

            var changedReplicaData = data.copy(
                value: newData,
                changingDate: timeProvider.currentTime
            )

            replicaState = replicaState.copy(data: changedReplicaData, loadingFromStorageRequired: false)
            try await storage?.write(data: newData)
        }
    }
}
