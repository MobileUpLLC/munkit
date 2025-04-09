/// Извлекает данные с сервера. Может выбросить ошибку при неудаче.
public typealias Fetcher<T> = @Sendable () async throws -> T
