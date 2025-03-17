/// Определяет базовое состояние загрузки данных для объекта.
public protocol AbstractLoadable {
    associatedtype Data

    /// Указывает, выполняется ли загрузка в данный момент.
    var loading: Bool { get }

    /// Данные, если они доступны, или nil, если загрузка ещё не завершена или произошла ошибка.
    var data: Data? { get }

    /// Ошибка загрузки, если она произошла, или nil, если ошибок нет.
    var error: CombinedLoadingError? { get }
}
