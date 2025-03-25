//
//  OptimisticUpdatesController.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 25.03.2025.
//

import Foundation

// Актор для управления оптимистичными обновлениями данных
actor OptimisticUpdatesController<T: Sendable> {
    private let timeProvider: TimeProvider
    private var replicaState: ReplicaState<T>
    private let storage: (any Storage<T>)?

    /// Инициализирует контроллер оптимистичных обновлений с заданным начальным состоянием и зависимостями.
    /// - Parameters:
    ///   - timeProvider: Провайдер текущего времени для отметки изменений.
    ///   - initialState: Начальное состояние реплики.
    ///   - storage: Опциональное хранилище для записи данных.
    init(timeProvider: TimeProvider, initialState: ReplicaState<T>, storage: (any Storage<T>)?) {
        self.timeProvider = timeProvider
        self.replicaState = initialState
        self.storage = storage
    }

    /// Начинает оптимистичное обновление, добавляя его в список ожидающих обновлений.
    /// - Parameter update: Оптимистичное обновление для добавления.
    func beginOptimisticUpdate(update: any OptimisticUpdate<T>) async {
        if let data = replicaState.data {
            let newOptimisticUpdates = data.optimisticUpdates + [update]
            replicaState = replicaState.copy(
                data: data.copy(optimisticUpdates: newOptimisticUpdates)
            )
        }
    }

    /// Подтверждает оптимистичное обновление, применяя его к данным и удаляя из списка ожидающих.
    /// - Parameter update: Оптимистичное обновление для подтверждения.
    /// - Throws: Ошибка, если запись в хранилище не удалась.
    func commitOptimisticUpdate(update: any OptimisticUpdate<T>) async throws {
        if let data = replicaState.data {
            let newData = update.apply(data.value)
            let newOptimisticUpdates = data.optimisticUpdates.filter { $0 !== update }
            replicaState = replicaState.copy(
                data: data.copy(
                    value: newData,
                    optimisticUpdates: newOptimisticUpdates,
                    changingTime: timeProvider.currentTime
                )
            )
            try await storage?.write(data: newData)
        }
    }

    /// Откатывает оптимистичное обновление, удаляя его из списка ожидающих без изменения данных.
    /// - Parameter update: Оптимистичное обновление для отката.
    func rollbackOptimisticUpdate(update: any OptimisticUpdate<T>) async {
        if let data = replicaState.data {
            let newOptimisticUpdates = data.optimisticUpdates.filter { $0 !== update }
            replicaState = replicaState.copy(
                data: data.copy(optimisticUpdates: newOptimisticUpdates)
            )
        }
    }
}
