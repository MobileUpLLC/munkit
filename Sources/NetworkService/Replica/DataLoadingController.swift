import Foundation

/// Контроллер загрузки данных для управления состоянием и событиями реплики.
actor DataLoadingController<T> where T: Sendable {
    /// Состояние реплики
    private var replicaState: ReplicaState<T>
    /// Поток событий реплики.
    private let replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation

    /// Загрузчик данных для выполнения операций загрузки.
    private let dataLoader: DataLoader<T>

    init(
        replicaState: ReplicaState<T>,
        replicaStateStream: AsyncStream<ReplicaState<T>>,
        replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation,
        dataLoader: DataLoader<T>
    ) {
        self.replicaState = replicaState
        self.replicaEventStreamContinuation = replicaEventStreamContinuation
        self.dataLoader = dataLoader

        /// Запускаем асинхронную задачу для обработки потока вывода загрузчика данных
        Task {
            for await output in dataLoader.outputStream {
                await onDataLoaderOutput(output: output)
            }
        }

        Task {
            await subscribeForReplicaStreams(replicaStateStream: replicaStateStream)
        }
    }

    private func subscribeForReplicaStreams(replicaStateStream: AsyncStream<ReplicaState<T>>) async {
        Task {
            for await newReplicaState in replicaStateStream {
                replicaState = newReplicaState
            }
        }
    }

    /// Обновляет данные реплики, игнорируя проверку свежести.
    func refresh() async {
        await loadData(skipLoadingIfFresh: false)
    }

    /// Повторно проверяет данные реплики, пропуская загрузку, если данные свежие.
    func revalidate() async {
        await loadData(skipLoadingIfFresh: true)
    }

    /// Отменяет текущую операцию загрузки данных.
    func cancel() async {
        guard replicaState.loading else {
            return
        }

        await dataLoader.cancel()

        let replicaState = replicaState.copy(
            loading: false,
            dataRequested: false,
            preloading: false
        )

        replicaEventStreamContinuation.yield(.loading(.loadingFinished(.canceled(replicaState))))
    }

    /// Обновляет данные после инвалидации в зависимости от указанного режима.
    /// - Parameter invalidationMode: Режим инвалидации, определяющий необходимость обновления.
    func refreshAfterInvalidation(invalidationMode: InvalidationMode) async {
        if replicaState.loading {
            await cancel()
            await refresh()
            return
        }

        switch invalidationMode {
        case .dontRefresh:
            break
        case .refreshIfHasObservers:
            if replicaState.observingState.status != .none {
                await refresh()
            }
        case .refreshIfHasActiveObservers:
            if replicaState.observingState.status == .active {
                await refresh()
            }
        case .refreshAlways:
            await refresh()
        }
    }

    /// Получает данные реплики, с возможностью принудительного обновления.
    ///  - Parameters:
    ///   - forceRefresh: Если true, данные будут обновлены независимо от их свежести.
    func getData(forceRefresh: Bool) async throws -> T {
        if forceRefresh == false, let data = replicaState.data, data.isFresh {
            return data.valueWithOptimisticUpdates
        }

        let outputStream = AsyncStream<DataLoader<T>.Output> { continuation in
            Task {
                await loadData(skipLoadingIfFresh: false, setDataRequested: true)

                for await output in dataLoader.outputStream {
                    continuation.yield(output)
                    if case .loadingFinished = output {
                        continuation.finish()
                    }
                }
            }
        }

        for await output in outputStream {
            switch output {
            case .loadingFinished(.success(let data)):
                let optimisticUpdates = replicaState.data?.optimisticUpdates
                return optimisticUpdates?.applyAll(to: data) ?? data
            case .loadingFinished(.error(let exception)):
                throw exception
            default:
                continue
            }
        }
        throw ServerError.unknown(details: ErrorDetails(message: "Данные не загружены"))
    }

    /// Запускает процесс загрузки данных с учетом параметров.
    /// - Parameters:
    ///   - skipLoadingIfFresh: Пропускает загрузку, если данные свежие.
    ///   - setDataRequested: Устанавливает флаг запроса данных.
    private func loadData(skipLoadingIfFresh: Bool, setDataRequested: Bool = false) async {
        if skipLoadingIfFresh && replicaState.hasFreshData {
            return
        }

        let loadingStarted: Bool

        if replicaState.loading == false {
            await dataLoader.load(loadingFromStorageRequired: replicaState.loadingFromStorageRequired)
            loadingStarted = true
        } else {
            loadingStarted = false
        }

        let preloading = replicaState.observingState.status == .none

        let replicaState = replicaState.copy(
            loading: true,
            dataRequested: setDataRequested || replicaState.dataRequested,
            preloading: preloading || replicaState.preloading
        )

        if loadingStarted {
            replicaEventStreamContinuation.yield(.loading(.loadingStarted(replicaState)))
        }
    }

    /// Обрабатывает вывод от загрузчика данных и обновляет состояние реплики.
    /// - Parameter output: Результат работы загрузчика данных.
    private func onDataLoaderOutput(output: DataLoader<T>.Output) async {
        switch output {
        case .storageRead(.data(let data)):
            let data = ReplicaData(value: data, isFresh: false, changingDate: .now)

            if replicaState.data == nil {
                let replicaState = replicaState.copy(data: data, loadingFromStorageRequired: false)
                replicaEventStreamContinuation.yield(.loading(.dataFromStorageLoaded(replicaState)))
            }

        case .storageRead(.empty):
            fatalError()
        case .loadingFinished(.success(let data)):
            let data = ReplicaData(
                value: data,
                isFresh: true,
                changingDate: .now,
                optimisticUpdates: replicaState.data?.optimisticUpdates ?? []
            )

            let replicaState = replicaState.copy(
                loading: false,
                data: data,
                error: nil,
                dataRequested: false,
                preloading: false
            )
            replicaEventStreamContinuation.yield(.loading(.loadingFinished(.success(replicaState))))
            replicaEventStreamContinuation.yield(.freshness(.freshened))

        case .loadingFinished(.error(let error)):
            let replicaState = replicaState.copy(
                loading: false,
                error: error,
                dataRequested: false,
                preloading: false
            )
            replicaEventStreamContinuation.yield(.loading(.loadingFinished(.error(replicaState))))
        }
    }
}
