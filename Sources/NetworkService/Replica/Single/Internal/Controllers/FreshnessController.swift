//
//  FreshnessController.swift
//  NetworkService
//
//  Created by Natalia Luzyanina on 25.03.2025.
//

import Foundation

/// Контроллер свежести данных реплики.
actor FreshnessController<T: Sendable> {
    /// Поток состояния реплики.
    private let replicaStateFlow: MutableStateFlow<ReplicaState<T>>

    /// Поток событий реплики.
    private let replicaEventFlow: MutableSharedFlow<ReplicaEvent<T>>

    // MARK: - Инициализация

    /// Инициализирует контроллер свежести.
    /// - Parameters:
    ///   - replicaStateFlow: Поток состояния реплики.
    ///   - replicaEventFlow: Поток событий реплики.
    init(replicaStateFlow: MutableStateFlow<ReplicaState<T>>, replicaEventFlow: MutableSharedFlow<ReplicaEvent<T>>) {
        self.replicaStateFlow = replicaStateFlow
        self.replicaEventFlow = replicaEventFlow
    }

    /// Помечает данные как устаревшие.
    func invalidate() async {
        let state = await replicaStateFlow.value
        if state.data?.isFresh == true {
            replicaStateFlow.value = state.copy(
                data: state.data?.copy(isFresh: false)
            )
            await replicaEventFlow.emit(ReplicaEvent<T>.freshness(.becameStale))
        }
    }

    /// Помечает данные как свежие.
    func makeFresh() async {
        let state = await replicaStateFlow.value
        if state.data != nil {
            replicaStateFlow.value = state.copy(
                data: state.data?.copy(isFresh: true)
            )
            await replicaEventFlow.emit(ReplicaEvent<T>.freshness(.freshened))
        }
    }
}
