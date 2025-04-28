//
//  InvalidationMode.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

/// Определяет поведение реплики после инвалидации.
public enum InvalidationMode: Sendable {
    /// Не обновлять реплику после инвалидации.
    case dontRefresh

    /// Обновлять реплику, только если у неё есть наблюдатели.
    case refreshIfHasObservers

    /// Обновлять реплику, только если у неё есть активные наблюдатели.
    case refreshIfHasActiveObservers

    /// Всегда обновлять реплику после инвалидации, независимо от наличия наблюдателей.
    case refreshAlways
}
