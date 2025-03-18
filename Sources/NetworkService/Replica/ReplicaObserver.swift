import Foundation

/// Наблюдатель за репликой, предоставляющий обновления состояния и ошибок.
public protocol ReplicaObserver {
    associatedtype ReplicaData

    /// Поток состояний реплики для отображения на UI.
    var stateFlow: AsyncStream<LoadableReplicaState<ReplicaData>> { get }

    /// Поток событий ошибок загрузки.
    var loadingErrorFlow: AsyncStream<LoadingError> { get }

    /// Прекращает наблюдение вручную.
    func cancelObserving()
}

public extension ReplicaObserver {
    /// Текущее состояние реплики (асинхронный доступ).
    var currentState: LoadableReplicaState<ReplicaData> {
        get async {
            var lastState: LoadableReplicaState<ReplicaData> = LoadableReplicaState()
            for await state in stateFlow {
                lastState = state
                break
            }
            return lastState
        }
    }
}
