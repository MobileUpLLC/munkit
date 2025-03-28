/// Интерфейс для сохранения данных реплики в постоянное хранилище.
public protocol Storage<T>: Sendable {
    associatedtype T

    /// Записывает данные в хранилище.
    func write(data: T) async throws

    /// Читает данные из хранилища.
    func read() async throws -> T?

    /// Удаляет данные из хранилища.
    func remove() async throws
}
