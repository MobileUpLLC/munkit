import Foundation

/// Наблюдатель за репликой, предоставляющий обновления состояния и ошибок.
public protocol ReplicaObserver<T>: Sendable {
    associatedtype T
    
    /// Поток состояний реплики для отображения на UI.
    func getStateFlow() async -> AsyncStream<LoadableReplicaState<T>>
    /// Поток событий ошибок загрузки.
    func getLoadingErrorFlow() async -> AsyncStream<LoadingError>
    /// Прекращает наблюдение вручную.
    func cancelObserving() async
}

public extension ReplicaObserver {
    /// Текущее состояние реплики (асинхронный доступ).
    var currentState: LoadableReplicaState<T> {
        get async {
            var lastState: LoadableReplicaState<T> = LoadableReplicaState()
            for await state in await getStateFlow() {
                lastState = state
                break
            }
            return lastState
        }
    }
}
