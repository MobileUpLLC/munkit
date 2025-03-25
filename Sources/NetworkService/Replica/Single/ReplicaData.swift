import Foundation

/// Данные, хранимые в реплике.
struct ReplicaData<T: Sendable>: Sendable {
    let value: T
    var isFresh: Bool
    let changingDate: Date
    let optimisticUpdates: [OptimisticUpdate<T>]

    /// Значение с применёнными оптимистичными обновлениями.
    var valueWithOptimisticUpdates: T {
        optimisticUpdates.applyAll(to: value)
    }

    init(
        value: T,
        isFresh: Bool,
        changingDate: Date,
        optimisticUpdates: [OptimisticUpdate<T>] = []
    ) {
        self.value = value
        self.isFresh = isFresh
        self.changingDate = changingDate
        self.optimisticUpdates = optimisticUpdates
    }

    /// Метод для создания копии состояния с возможностью изменения некоторых свойств.
    func copy(
        value: T? = nil,
        isFresh: Bool? = nil,
        changingDate: Date? = nil,
        optimisticUpdates: [OptimisticUpdate<T>]? = nil
    ) -> ReplicaData {
        return ReplicaData(
            value: value ?? self.value,
            isFresh: isFresh ?? self.isFresh,
            changingDate: changingDate ?? self.changingDate,
            optimisticUpdates: optimisticUpdates ?? self.optimisticUpdates
        )
    }
}
