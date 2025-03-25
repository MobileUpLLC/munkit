import Foundation

/// Контроллер загрузки данных для управления состоянием и событиями реплики.
actor DataLoadingController<T: Sendable> {
    // MARK: - Свойства

    /// Провайдер времени для получения текущего времени при обновлении данных.
    private let timeProvider: any TimeProvider

    /// Поток состояния реплики, содержащий текущее состояние (загрузка, данные, ошибки и т.д.).
    private let replicaStateFlow: MutableStateFlow<ReplicaState<T>>

    /// Поток событий реплики, через который передаются события загрузки и обновления.
    private let replicaEventFlow: MutableSharedFlow<ReplicaEvent<T>>

    /// Загрузчик данных, ответственный за получение данных из источника или хранилища.
    private let dataLoader: DataLoader<T>

    // MARK: - Инициализация

    /// Инициализирует контроллер загрузки данных.
    /// - Parameters:
    ///   - timeProvider: Провайдер времени для фиксации времени изменения данных.
    ///   - replicaStateFlow: Поток состояния реплики.
    ///   - replicaEventFlow: Поток событий реплики.
    ///   - dataLoader: Загрузчик данных для выполнения операций загрузки.
    init(
        timeProvider: any TimeProvider,
        replicaStateFlow: MutableStateFlow<ReplicaState<T>>,
        replicaEventFlow: MutableSharedFlow<ReplicaEvent<T>>,
        dataLoader: DataLoader<T>
    ) {
        self.timeProvider = timeProvider
        self.replicaStateFlow = replicaStateFlow
        self.replicaEventFlow = replicaEventFlow
        self.dataLoader = dataLoader

        // Запускаем асинхронную задачу для обработки потока вывода загрузчика данных
        _Concurrency.Task {
            for await output in await dataLoader.outputFlow {
                await onDataLoaderOutput(output: output)
            }
        }
    }

    // MARK: - Методы

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
        let state = await replicaStateFlow.value
        guard state.loading else { return }

        await dataLoader.cancel()

        replicaStateFlow.value = state.copy(
            loading: false,
            dataRequested: false,
            preloading: false
        )

        await replicaEventFlow.emit(ReplicaEvent<T>.loading(.loadingFinished(.canceled)))
    }

    /// Обновляет данные после инвалидации в зависимости от указанного режима.
    /// - Parameter invalidationMode: Режим инвалидации, определяющий необходимость обновления.
    func refreshAfterInvalidation(invalidationMode: InvalidationMode) async {
        let state = await replicaStateFlow.value

        // Если загрузка уже идет, отменяем её и перезапускаем
        if state.loading {
            await cancel()
            await refresh()
            return
        }

        switch invalidationMode {
        case .dontRefresh:
            break
        case .refreshIfHasObservers:
            if state.observingState.status != .none {
                await refresh()
            }
        case .refreshIfHasActiveObservers:
            if state.observingState.status == .active {
                await refresh()
            }
        case .refreshAlways:
            await refresh()
        }
    }

    /// Получает данные реплики, с возможностью принудительного обновления.
    /// - forceRefresh: Если true, данные будут обновлены независимо от их свежести.
    func getData(forceRefresh: Bool) async throws -> T {
        if forceRefresh == false, let data = await replicaStateFlow.value.data, data.isFresh {
            return data.valueWithOptimisticUpdates
        }

        let outputStream = AsyncStream<DataLoader<T>.Output> { continuation in
            _Concurrency.Task {
                await loadData(skipLoadingIfFresh: false, setDataRequested: true)

                for await output in await dataLoader.outputFlow {
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
                let optimisticUpdates = await replicaStateFlow.value.data?.optimisticUpdates
                return optimisticUpdates?.applyAll(to: data) ?? data
            case .loadingFinished(.error(let exception)):
                throw exception
            default:
                continue
            }
        }
        throw LoadingError(
            reason: .normal,
            error: .unknown(details: .init(message: "Данные не загружены"))
        )
    }

    /// Запускает процесс загрузки данных с учетом параметров.
    /// - Parameters:
    ///   - skipLoadingIfFresh: Пропускает загрузку, если данные свежие.
    ///   - setDataRequested: Устанавливает флаг запроса данных.
    private func loadData(skipLoadingIfFresh: Bool, setDataRequested: Bool = false) async {
        let state = await replicaStateFlow.value

        if skipLoadingIfFresh && state.hasFreshData {
            return
        }

        var loadingStarted: Bool
        if state.loading == false {
            loadingStarted = true
            await dataLoader.load(loadingFromStorageRequired: state.loadingFromStorageRequired)
        } else {
            loadingStarted = false
        }

        let preloading = state.observingState.status == .none

        replicaStateFlow.value = state.copy(
            loading: true,
            dataRequested: setDataRequested || state.dataRequested,
            preloading: preloading || state.preloading
        )

        if loadingStarted {
            await replicaEventFlow.emit(ReplicaEvent<T>.loading(.loadingStarted))
        }
    }

    /// Обрабатывает вывод от загрузчика данных и обновляет состояние реплики.
    /// - Parameter output: Результат работы загрузчика данных.
    private func onDataLoaderOutput(output: DataLoader<T>.Output) async {
        let state = await replicaStateFlow.value

        switch output {
        case .storageRead(.data(let data)):
            if state.data == nil {
                replicaStateFlow.value = state.copy(
                    data: ReplicaData(
                            value: data,
                            isFresh: false,
                            changingDate: timeProvider.currentTime
                        ),
                    loadingFromStorageRequired: false
                )
                await replicaEventFlow.emit(.loading(.dataFromStorageLoaded(data: data)))
            }
        case .storageRead(.empty):
            replicaStateFlow.value = state.copy(loadingFromStorageRequired: false)

        case .loadingFinished(.success(let data)):
            replicaStateFlow.value = state.copy(
                loading: false,
                data:  ReplicaData(
                    value: data,
                    isFresh: true,
                    changingDate: timeProvider.currentTime,
                    optimisticUpdates: state.data?.optimisticUpdates ?? []
                ),
                error: nil,
                dataRequested: false,
                preloading: false
            )
            await replicaEventFlow.emit(.loading(.loadingFinished(.success(data: data))))
            await replicaEventFlow.emit(.freshness(.freshened))

        case .loadingFinished(.error(let error)):
            replicaStateFlow.value = state.copy(
                loading: false,
                error: LoadingError(reason: .normal, error: error),
                dataRequested: false,
                preloading: false
            )
            await replicaEventFlow.emit(.loading(.loadingFinished(.error(error))))
        }
    }
}
