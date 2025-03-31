import Foundation

actor DataLoader<T> where T: Sendable {
    enum Output {
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

    /// Поток событий, генерируемых загрузчиком данных.
    let outputStream: AsyncStream<Output>

    /// Используется для отправки новых событий в поток и завершения его работы.
    private var outputContinuation: AsyncStream<Output>.Continuation?

    /// Опциональное хранилище, используемое для чтения и записи данных типа `T`.
    private let storage: (any Storage<T>)?

    /// Интерфейс для получения данных из внешнего источника.
    private let fetcher: any Fetcher<T>

    /// Асинхронная задача, выполняющая текущую операцию загрузки.
    private var loadingTask: Task<Void, Never>?

    init(storage: (any Storage<T>)?, fetcher: any Fetcher<T>) {
        self.storage = storage
        self.fetcher = fetcher

        let (stream, continuation) = AsyncStream.makeStream(of: Output.self)
        self.outputStream = stream
        self.outputContinuation = continuation
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
                    if Task.isCancelled {
                        return
                    }

                    if let data = try await storage?.read() {
                        await outputContinuation?.yield(.storageRead(.data(data)))
                    } else {
                        await outputContinuation?.yield(.storageRead(.empty))
                    }
                }

                let data = try await fetcher.fetch()

                try Task.checkCancellation()

                if let storage = storage {
                    try await storage.write(data: data)
                }

                try Task.checkCancellation()

                await outputContinuation?.yield(.loadingFinished(.success(data)))

            } catch is CancellationError {
                return
            } catch {
                if !Task.isCancelled {
                    await outputContinuation?.yield(.loadingFinished(.error(error)))
                }
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
        outputContinuation?.finish()
    }
}

