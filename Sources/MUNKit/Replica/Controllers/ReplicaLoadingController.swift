import Foundation

/// Контроллер загрузки данных для управления состоянием и событиями реплики.
actor ReplicaLoadingController<T> where T: Sendable {
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
            for await output in dataLoader.outputStreamBundle.stream {
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

        replicaEventStreamContinuation.yield(.loading(.loadingFinished(.canceled)))
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

                for await output in dataLoader.outputStreamBundle.stream {
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
        throw LoadingError()
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

        let dataRequested: Bool = setDataRequested || replicaState.dataRequested
        let preloading: Bool = (replicaState.observingState.status == .none) || replicaState.preloading

        if loadingStarted {
            replicaEventStreamContinuation.yield(
                .loading(.loadingStarted(dataRequested: dataRequested, preloading: preloading))
            )
        }
    }

    /// Обрабатывает вывод от загрузчика данных и обновляет состояние реплики.
    /// - Parameter output: Результат работы загрузчика данных.
    private func onDataLoaderOutput(output: DataLoader<T>.Output) async {
        switch output {
        case .storageRead(.data(let data)):
            let data = ReplicaData(value: data, isFresh: false, changingDate: .now)

            if replicaState.data == nil {
                replicaEventStreamContinuation.yield(.loading(.dataFromStorageLoaded(data: data)))
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

            replicaEventStreamContinuation.yield(.loading(.loadingFinished(.success(data: data))))
            replicaEventStreamContinuation.yield(.freshness(.freshened))

        case .loadingFinished(.error(let error)):
            replicaEventStreamContinuation.yield(.loading(.loadingFinished(.error(error))))
        }
    }
}
