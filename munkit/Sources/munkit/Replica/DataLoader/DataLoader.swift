//
//  DataLoader.swift
//  MUNKit
//
//  Created by Natalia Luzyanina on 01.04.2025.
//

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

