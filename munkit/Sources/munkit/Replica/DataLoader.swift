//
//  DataLoader.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

import Foundation

enum DataLoaderOutput<T: Sendable> {
    case storageRead(StorageRead)
    case loadingFinished(LoadingFinished)

    /// Результат чтения из хранилища.
    enum StorageRead {
        case data(T)
        case empty
    }

    /// Результат завершения загрузки.
    enum LoadingFinished {
        case success(T)
        case error(Error)
    }
}

extension DataLoaderOutput: CustomStringConvertible {
    var description: String {
        switch self {
        case .storageRead(
            let read
        ): return "Storage read: (read)" case .loadingFinished(
            let finished
        ): return "Loading finished: (finished)"
        }
    }
}

extension DataLoaderOutput.StorageRead: CustomStringConvertible {
    var description: String {
        switch self {
        case .data: return "Data found" case .empty: return "No data"
        }
    }
}

extension DataLoaderOutput.LoadingFinished: CustomStringConvertible {
    var description: String {
        switch self {
        case .success: return "Success" case .error(let error): return "Error: (error)"
        }
    }
}


actor DataLoader<T> where T: Sendable {
    typealias Output = DataLoaderOutput<T>

    let outputStreamBundle: AsyncStreamBundle<Output>
    /// Опциональное хранилище, используемое для чтения и записи данных типа `T`.
    private let storage: (any Storage<T>)?

    /// Интерфейс для получения данных из внешнего источника.
    private let fetcher: @Sendable () async throws -> T

    /// Асинхронная задача, выполняющая текущую операцию загрузки.
    private var loadingTask: Task<Void, Never>?

    init(storage: (any Storage<T>)?, fetcher: @Sendable @escaping () async throws -> T) {
        self.storage = storage
        self.fetcher = fetcher
        self.outputStreamBundle = AsyncStream.makeStream(of: Output.self)
    }

    /// Этот метод сначала пытается прочитать данные из хранилища (если  требуется), затем загружает данные из внешнего источника через `fetcher`. Результаты передаются через `outputFlow`.
    /// - Parameter loadingFromStorageRequired: Указывает, нужно ли сначала пытаться загрузить данные из хранилища.
    ///  Результаты загрузки передаются в поток `outputStream` в виде событий `Output`.
    func load(loadingFromStorageRequired: Bool) async {
        await cancel()

        loadingTask = Task { [weak self] in
            guard let self else { return }

            do {
                if loadingFromStorageRequired {
                    if let data = try await storage?.read() {
                        try Task.checkCancellation()
                        outputStreamBundle.continuation.yield(.storageRead(.data(data)))
                    } else {
                        outputStreamBundle.continuation.yield(.storageRead(.empty))
                    }
                }

                let data = try await fetcher()
                try Task.checkCancellation()

                if let storage = storage {
                    try await storage.write(data: data)
                    try Task.checkCancellation()
                }
                outputStreamBundle.continuation.yield(.loadingFinished(.success(data)))
            } catch is CancellationError {
                return
            } catch {
                outputStreamBundle.continuation.yield(.loadingFinished(.error(error)))
            }
        }
    }

    /// Отменяет текущую операцию загрузки данных.
    func cancel() async {
        loadingTask?.cancel()
        loadingTask = nil
    }

    /// Освобождает ресурсы, связанные с загрузчиком данных.
    deinit {
        outputStreamBundle.continuation.finish()
    }
}

