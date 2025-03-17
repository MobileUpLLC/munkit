/// утилиты для выполнения оптимистичных обновлений данных.
/// оптимистичное обновление - это, например, изменение UI до подтверждения сервером
public struct OptimisticUpdateUtility {
    /// Функция для выполнения оптимистичного обновления данных.
    public typealias Update<T> = (T) -> T where T: AnyObject

    /// Применяет список оптимистичных обновлений к данным.
    public static func applyAll<T>(updates: [Update<T>], to data: T) -> T {
        updates.reduce(data) { result, update in update(result) }
    }

    /// Выполняет оптимистичное обновление с возможностью отката при ошибке или отмене.
    ///
    /// - Parameters:
    ///   - begin: Действие, выполняемое перед началом операции.
    ///   - commit: Действие, выполняемое при успешном завершении.
    ///   - rollback: Действие отката, выполняемое при ошибке или отмене.
    ///   - onSuccess: Опциональный коллбек при успехе.
    ///   - onError: Опциональный коллбек при ошибке.
    ///   - onCanceled: Опциональный коллбек при отмене.
    ///   - onFinished: Опциональный коллбек после завершения (успех, ошибка или отмена).
    ///   - block: Основная операция, возвращающая результат.
    /// - Returns: Результат операции.
    /// - Throws: Перебрасывает исключения из `block`.
    public static func performOptimisticUpdate<R>(
        begin: () -> Void,
        commit: () -> Void,
        rollback: () async -> Void,
        onSuccess: (() async -> Void)? = nil,
        onError: ((Error) async -> Void)? = nil,
        onCanceled: (() async -> Void)? = nil,
        onFinished: (() async -> Void)? = nil,
        block: () async throws -> R
    ) async throws -> R {
        begin()
        do {
            let result = try await block()
            commit()
            await onSuccess?()
            await onFinished?()
            return result
        } catch is CancellationError {
            // Откатываем изменения даже при отмене задачи
            await rollback()
            await onCanceled?()
            await onFinished?()
            throw CancellationError()
        } catch {
            // Откатываем изменения при любой другой ошибке
            await rollback()
            await onError?(error)
            await onFinished?()
            throw error
        }
    }
}
