import Foundation

// public typealias OptimisticUpdate<T> = (T) -> T

/// Протокол, представляющий действие для оптимистичного обновления данных.
/// Определяет функцию, которая применяет обновление к данным типа `T`.
public protocol OptimisticUpdate<T>: Sendable, AnyObject {
    associatedtype T: Sendable
    /// Применяет оптимистичное обновление к данным.
    /// - Parameter data: Текущие данные типа `T`.
    /// - Returns: Обновленные данные после применения действия.
    func apply(_ data: T) -> T
}

/// Управляет выполнением оптимистичных (до подтверждения сервером) обновлений. 
actor OptimisticUpdateManager {
    /// Выполняет оптимистичное обновление с указанными действиями для начала, подтверждения, отката и обработки результатов.
    /// - Parameters:
    ///   - begin: Действие, выполняемое перед началом операции.
    ///   - commit: Действие, выполняемое при успешном завершении.
    ///   - rollback: Асинхронное действие для отката при ошибке или отмене.
    ///   - onSuccess: Опциональный callback для успеха.
    ///   - onError: Опциональный callback для обработки ошибки.
    ///   - onCanceled: Опциональный callback для отмены.
    ///   - onFinished: Опциональный callback, вызываемый в конце независимо от результата.
    ///   - block: Асинхронный блок, выполняющий основную операцию.
    /// - Returns: Результат выполнения блока.
    /// - Throws: Перебрасывает ошибки из блока или отмену.
    func performOptimisticUpdate<T: Sendable>(
        begin: () -> Void,
        commit: () -> Void,
        rollback: () async -> Void,
        onSuccess: (() async -> Void)? = nil,
        onError: ((Error) async -> Void)? = nil,
        onCanceled: (() async -> Void)? = nil,
        onFinished: (() async -> Void)? = nil,
        block: () async throws -> T
    ) async throws -> T {
        begin()
        do {
            let result = try await block()
            commit()
            await onSuccess?()
            await onFinished?()
            return result
        } catch is CancellationError {
            await rollback()
            await onCanceled?()
            await onFinished?()
            throw CancellationError()
        } catch {
            await rollback()
            await onError?(error)
            await onFinished?()
            throw error
        }
    }
}

/// Расширение для массива оптимистичных обновлений, позволяющее применить все обновления к данным.
/// - Parameter data: Исходные данные типа `T`.
/// - Returns: Данные после последовательного применения всех обновлений.
extension Array {
    func applyAll<T>(to data: T) -> T where Element == any OptimisticUpdate<T> {
        reduce(data) { result, update in
            update.apply(result)
        }
    }
}
