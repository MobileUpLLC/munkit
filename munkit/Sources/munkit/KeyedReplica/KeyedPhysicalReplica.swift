//
//  KeyedPhysicalReplica.swift
//  munkit
//
//  Created by Natalia Luzyanina on 16.04.2025.
//

import Foundation

public protocol KeyedPhysicalReplica<K, T>: KeyedReplica where K: Hashable & Sendable, T: Sendable {
    /// Уникальный идентификатор реплики
    var id: String { get }

    /// Человекочитаемое имя (для отладки)
    var name: String { get }

    /// Возвращает текущее состояние реплики для указанного ключа
    func getCurrentState(for key: K) -> ReplicaState<T>?

    /// Заменяет текущие данные новыми для указанного ключа
    /// Примечание: Не влияет на свежесть данных
    func setData(_ data: T, for key: K) async throws

    /// Модифицирует текущие данные с помощью функции преобразования, если они существуют для ключа
    /// Примечание: Не влияет на свежесть данных
    func mutateData(for key: K, transform: @Sendable (T) throws -> T) async throws

    // MARK: - Управление данными

    /// Помечает данные как устаревшие для указанного ключа (если они существуют)
    /// Может инициировать обновление в зависимости от режима InvalidationMode
    func invalidate(key: K, mode: InvalidationMode) async

    /// Помечает данные как свежие для указанного ключа (если они существуют)
    func makeFresh(key: K) async

    /// Отменяет текущий запрос для указанного ключа (если он выполняется)
    func cancel(key: K)

    /// Отменяет запрос и очищает данные для указанного ключа
    /// Параметр removeFromStorage определяет, будут ли данные удалены из хранилища
    func clear(key: K, removeFromStorage: Bool) async

    /// Очищает ошибку в состоянии реплики для указанного ключа
    func clearError(key: K) async

    /// Отменяет все сетевые запросы и очищает данные во всех дочерних репликах
    func clearAll() async

    // MARK: - Оптимистичные обновления

    /// Начинает оптимистичное обновление для указанного ключа
    /// Наблюдаемые данные будут немедленно преобразованы функцией update
    func beginOptimisticUpdate(key: K, update: OptimisticUpdate<T>) async

    /// Подтверждает оптимистичное обновление для указанного ключа
    /// Реплика "забывает" предыдущие данные
    func commitOptimisticUpdate(key: K, update: OptimisticUpdate<T>) async

    /// Откатывает оптимистичное обновление для указанного ключа
    /// Наблюдаемые данные возвращаются к исходному состоянию
    func rollbackOptimisticUpdate(key: K, update: OptimisticUpdate<T>) async

    // MARK: - Доступ к репликам

    /// Выполняет действие с PhysicalReplica для указанного ключа
    /// Если реплика не существует - создает ее
    func withReplica(key: K, action: @Sendable (any PhysicalReplica<T>) async throws -> Void) async throws

    /// Выполняет действие с PhysicalReplica для указанного ключа, если она существует
    func withExistingReplica(key: K, action: @Sendable (any PhysicalReplica<T>) async throws -> Void) async throws

    /// Выполняет действие для каждой дочерней PhysicalReplica
    func forEachReplica(action: @Sendable (K, any PhysicalReplica<T>) async throws -> Void) async throws
}
