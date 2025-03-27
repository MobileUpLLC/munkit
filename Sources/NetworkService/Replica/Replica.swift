import Foundation

/// Протокол базовой реплики с минимальным API.
public protocol Replica<T> {
    associatedtype T

    /// Начинает наблюдение за репликой.
    func observe(observerHost: ReplicaObserverHost) async -> any ReplicaObserver

    /// Загружает свежие данные из сети.
    /// - Note: Не вызывает новый запрос, если другой уже выполняется.
    func refresh() async

    /// Загружает свежие данные из сети, если текущие данные устарели.
    /// - Note: Не вызывает новый запрос, если другой уже выполняется.
    func revalidate() async

    /// Загружает и возвращает данные.
    /// - Parameter forceRefresh: Принудительно выполняет запрос, даже если данные свежие.
    /// - Returns: Свежие данные.
    /// - Throws: Ошибка, если загрузка не удалась.
    /// - Note: Всегда возвращает свежие данные, выполняя запрос при необходимости.
    func getData(forceRefresh: Bool) async throws -> T
}
