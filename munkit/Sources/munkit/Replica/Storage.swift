//
//  Storage.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

/// Интерфейс для сохранения данных реплики в постоянное хранилище.
public protocol Storage<T>: Sendable {
    associatedtype T: Sendable

    /// Записывает данные в хранилище.
    func write(data: T) async throws

    /// Читает данные из хранилища.
    func read() async throws -> T?

    /// Удаляет данные из хранилища.
    func remove() async throws
}
