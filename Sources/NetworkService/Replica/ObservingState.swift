import Foundation

/// Содержит информацию о наблюдателях реплики.
struct ObservingState {
    let observerIds: Set<UUID>
    let activeObserverIds: Set<UUID>
    /// Время последнего наблюдения за репликой.
    let observingTime: ObservingTime
    /// Количество наблюдателей.
    var observerCount: Int { observerIds.count }
    /// Количество активных наблюдателей.
    var activeObserverCount: Int { activeObserverIds.count }

    /// Текущий статус наблюдения, основанный на количестве наблюдателей.
    var status: ObservingStatus {
        if activeObserverCount > 0 {
            return .active
        } else if observerCount > 0 {
            return .inactive
        } else {
            return .none
        }
    }
}

/// Представляет статус наблюдателей для реплики.
/// - none - нет наблюдателей
/// - inactive - eсть неактивные наблюдатели
/// - active - eсть активные наблюдатели
enum ObservingStatus {
    case none
    case inactive
    case active
}

/// Представляет время последнего наблюдения за репликой.
/// - never - никогда не наблюдалась
/// - timeInPast -  время в прошлом
/// - now - сейчас наблюдается
enum ObservingTime {
    case never
    case timeInPast(Date)
    case now
}
