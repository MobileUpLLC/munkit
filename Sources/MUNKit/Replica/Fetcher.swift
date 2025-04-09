/// Извлекает данные с сервера. Может выбросить ошибку при неудаче.
//public protocol Fetcher<T>: Sendable {
//    associatedtype T
//
//    /// Выполняет запрос данных.
//    func fetch() async throws -> T
//}

//public typealias Fetcher<T> = () async throws -> T

public typealias Fetcher<T> = @Sendable () async throws -> T
