import Foundation

/// `DataLoader` предоставляет возможность асинхронно загружать данные из хранилища (если оно доступно) или из внешнего источника через `Fetcher`. Результаты загрузки передаются через поток `outputFlow` в виде событий `Output`.
/// storage - Опциональное хранилище, из которого можно читать и в которое можно записывать данные типа T
/// fetcher - Интерфейс для получения данных из внешнего источника.
actor DataLoader<T: Sendable> {
    /// Перечисление Output моделирует возможные события, которые DataLoader может отправлять через outputFlow
    enum Output {
        /// Событие чтения данных из хранилища
        case storageRead(StorageRead)
        /// Событие завершения загрузки данных из внешнего источника
        case loadingFinished(LoadingFinished)

        enum StorageRead: Sendable {
            /// Успешное чтение данных из хранилища.
            case data(T)
            /// Хранилище не содержит данных.
            case empty
        }

        enum LoadingFinished: Sendable {
            /// Успешное завершение загрузки с данными.
            case success(T)
            /// Ошибка при загрузке данных.
            case error(Error)
        }
    }

    /// Опциональное хранилище, используемое для чтения и записи данных типа `T`.
    private let storage: (any Storage<T>)?

    /// Интерфейс для получения данных из внешнего источника.
    /// Используется для асинхронной загрузки данных, если они недоступны в хранилище или требуется обновление.
    private let fetcher: any Fetcher<T>

    /// Поток событий, генерируемых загрузчиком данных.
    private(set) lazy var outputFlow: AsyncStream<Output> = {
        AsyncStream { continuation in
            self.outputContinuation = continuation
        }
    }()

    /// Используется для отправки новых событий в поток и завершения его работы.
    private var outputContinuation: AsyncStream<Output>.Continuation?

    /// Асинхронная задача, выполняющая текущую операцию загрузки.
    private var loadingTask: _Concurrency.Task<Void, Never>?

    init(storage: (any Storage<T>)?, fetcher: any Fetcher<T>) {
        self.storage = storage
        self.fetcher = fetcher
    }

    /// Запускает асинхронную загрузку данных.
    ///
    /// Этот метод сначала пытается прочитать данные из хранилища (если указано и требуется), затем загружает данные из внешнего источника через `fetcher`. Результаты передаются через `outputFlow`.
    ///
    /// - Parameter loadingFromStorageRequired: Указывает, нужно ли сначала пытаться загрузить данные из хранилища.
    /// - Note: Если предыдущая загрузка уже выполняется, она будет отменена перед началом новой.
    func load(loadingFromStorageRequired: Bool) async {
        await cancel()

        loadingTask = _Concurrency.Task { [weak self] in
            guard let self else { return }

            do {
                if let storage = storage, loadingFromStorageRequired {
                    let storageData = await storage.read()

                    if _Concurrency.Task.isCancelled {
                        return
                    }

                    if let data = storageData {
                        await outputContinuation?.yield(.storageRead(.data(data)))
                    } else {
                        await outputContinuation?.yield(.storageRead(.empty))
                    }
                }

                let data = try await fetcher.fetch()

                if _Concurrency.Task.isCancelled {
                    return
                }

                if let storage = storage {
                    try await storage.write(data: data)
                }

                if _Concurrency.Task.isCancelled {
                    return
                }

                await outputContinuation?.yield(.loadingFinished(.success(data)))

            } catch is CancellationError {
                return
            } catch {
                if !_Concurrency.Task.isCancelled {
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

