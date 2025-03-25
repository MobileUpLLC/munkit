//
//  File.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 25.03.2025.
//

import Foundation

// Актор для управления очисткой данных
actor ClearingController<T: Sendable> {
 //   private var replicaState: ReplicaState<T>
    private let storage: (any Storage<T>)?
    /// Поток состояния реплики.
    private let replicaStateFlow: MutableStateFlow<ReplicaState<T>>

    /// Поток событий реплики.
    private let replicaEventFlow: MutableSharedFlow<ReplicaEvent<T>>

//    private var replicaEventContinuation: AsyncStream<ReplicaEvent<T>>.Continuation?
//    private lazy var replicaEventFlow: AsyncStream<ReplicaEvent<T>> = {
//        AsyncStream { (continuation: AsyncStream<ReplicaEvent<T>>.Continuation) -> Void in
//            self.replicaEventContinuation = continuation
//        }
//    }()

    /// Инициализирует контроллер очистки с заданным начальным состоянием и хранилищем.
    /// - Parameters:
    ///   - initialState: Начальное состояние реплики.
    ///   - storage: Опциональное хранилище для удаления данных.
    init(replicaStateFlow: MutableStateFlow<ReplicaState<T>>, replicaEventFlow: MutableSharedFlow<ReplicaEvent<T>>, storage: (any Storage<T>)?) {
        self.replicaStateFlow = replicaStateFlow
        self.replicaEventFlow = replicaEventFlow
        self.storage = storage
    }

    /// Очищает состояние реплики и, при необходимости, данные в хранилище.
    /// - Parameter removeFromStorage: Если `true`, данные также удаляются из хранилища.
    func clear(removeFromStorage: Bool) async throws {

        replicaStateFlow.value = replicaState.copy(
            data: nil,
            error: nil,
            loadingFromStorageRequired: false
        )

        replicaEventContinuation?.yield(.cleared)

        if removeFromStorage {
            try await storage?.remove()
        }
    }

    /// Удаляет ошибку из состояния реплики, оставляя остальные данные нетронутыми.
    func clearError() async {
        replicaState = replicaState.copy(error: nil)
    }
}
