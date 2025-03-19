/// Извлекает данные с сервера. Может выбросить ошибку при неудаче.
public protocol Fetcher {
    associatedtype Data

    /// Выполняет запрос данных.
    func fetch() async throws -> Data
}
