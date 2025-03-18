/// Интерфейс для сохранения данных реплики в постоянное хранилище.
public protocol Storage {
    associatedtype Data

    /// Записывает данные в хранилище.
    func write(data: Data) async throws

    /// Читает данные из хранилища.
    func read() async throws -> Data?

    /// Удаляет данные из хранилища.
    func remove() async throws
}
