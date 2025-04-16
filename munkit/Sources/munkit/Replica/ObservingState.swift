//
//  ObservingState.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

/// Содержит информацию о наблюдателях реплики.
public struct ObservingState: Sendable {
    let observerIds: Set<UUID>
    let activeObserverIds: Set<UUID>
    /// Время последнего наблюдения за репликой.
    let observingTime: ObservingTime

    var observersCountInfo: ObserversCountInfo

    /// Текущий статус наблюдения, основанный на количестве наблюдателей.
    var status: ObservingStatus {
        if activeObserverIds.count > 0 {
            return .active
        } else if observerIds.count > 0 {
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
