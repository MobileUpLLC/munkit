//
//  Fetcher.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

/// Извлекает данные с сервера. Может выбросить ошибку при неудаче.
public typealias Fetcher<T> = @Sendable () async throws -> T
