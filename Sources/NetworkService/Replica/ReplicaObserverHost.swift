/// Обеспечивает функциональность для управления наблюдателями.
public struct ReplicaObserverHost {
    /// Задача, представляющая время жизни наблюдателя.
    /// При отмене этой задачи наблюдатель прекращает работу.
    let observerTask: _Concurrency.Task<Void, Never>

    /// Асинхронный поток, отправляющий значения активности наблюдателя.
    /// Позволяет реплике определить наличие активных наблюдателей.
    let observerActive: AsyncStream<Bool>

    /// Инициализирует новый экземпляр StandardReplicaObserverHost.
    /// - Parameters:
    ///   - task: Задача, определяющая время жизни наблюдателя
    ///   - initialActive: Начальное состояние активности наблюдателя
    init(task: Task<Void, Never>, observerActive: AsyncStream<Bool>) {
        self.observerTask = task
        self.observerActive = observerActive
    }
}
