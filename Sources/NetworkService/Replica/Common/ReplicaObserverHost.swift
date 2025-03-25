import Foundation

/// Протокол ReplicaObserverHost определяет сущности, способные создавать наблюдателей для реплик.
/// Он управляет жизненным циклом наблюдателя и контролирует его активное состояние.
public protocol ReplicaObserverHost: Sendable {
    /// Задача, представляющая время жизни наблюдателя.
    /// Наблюдатель прекращает наблюдение при отмене этой задачи.
    var observerTask: _Concurrency.Task<Void, Never> { get }
    /// Асинхронный поток, указывающий, активен ли наблюдатель в данный момент.
    /// Позволяет реплике определить наличие активных наблюдателей.
    var observerActive: AsyncStream<Bool> { get }
}

/// Стандартная реализация ReplicaObserverHost.
/// Обеспечивает конкретную функциональность для управления наблюдателями.
private actor StandardReplicaObserverHost: ReplicaObserverHost {
    /// Задача, представляющая время жизни наблюдателя.
    /// При отмене этой задачи наблюдатель прекращает работу.
    let observerTask: _Concurrency.Task<Void, Never>

    /// Асинхронный поток, отправляющий значения активности наблюдателя.
    let observerActive: AsyncStream<Bool>

    /// Инициализирует новый экземпляр StandardReplicaObserverHost.
    /// - Parameters:
    ///   - task: Задача, определяющая время жизни наблюдателя
    ///   - initialActive: Начальное состояние активности наблюдателя
    init(task: _Concurrency.Task<Void, Never>, observerActive: AsyncStream<Bool>) {
        self.observerTask = task
        self.observerActive = observerActive
    }
}
