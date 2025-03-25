import Foundation

protocol TimeProvider {
    var currentTime: Date { get }
}

actor PhysicalReplicaImpl<T: AnyObject & Sendable>: PhysicalReplica {
    let id = UUID()
    let name: String
    let settings: ReplicaSettings

    private let timeProvider: TimeProvider
    private let behaviours: [any ReplicaBehaviour]
    private let storage: (any Storage<T>)?
    private let fetcher: any Fetcher<T>
    
    private var stateContinuation: AsyncStream<ReplicaState<T>>.Continuation?
    private var eventContinuation: AsyncStream<ReplicaEvent<T>>.Continuation?

    private let stateFlow: MutableStateFlow<ReplicaState<T>>
    private let eventFlow: MutableSharedFlow<ReplicaEvent<T>>


    private let observersController: ObserversController<T>
    private let dataLoadingController: DataLoadingController<T>
    private let dataChangingController: DataChangingController<T>
    private let freshnessController: FreshnessController<T>
    private let clearingController: ClearingController<T>
    private let optimisticUpdatesController: OptimisticUpdatesController<T>

    init(
        timeProvider: any TimeProvider,
        dispatcher: DispatchQueue,
        name: String,
        settings: ReplicaSettings,
        behaviours: [any ReplicaBehaviour<T>],
        storage: (any Storage<T>)?,
        fetcher: any Fetcher<T>
    ) {
        self.timeProvider = timeProvider
        self.name = name
        self.settings = settings
        self.behaviours = behaviours
        self.storage = storage
        self.fetcher = fetcher
        
        self.observersController = ObserversController(timeProvider: timeProvider, initialState: stateFlow)
        self.dataLoadingController = DataLoadingController(
            timeProvider: timeProvider,
            replicaStateFlow: stateFlow,
            replicaEventFlow: eventFlow,
            dataLoader: DataLoader(storage: storage, fetcher: fetcher)
        )
        self.dataChangingController = DataChangingController(timeProvider: timeProvider, initialState: state, storage: storage)
        self.freshnessController = FreshnessController(replicaStateFlow: stateFlow, replicaEventFlow: eventFlow)
        self.clearingController = ClearingController(initialState: state, storage: storage)
        self.optimisticUpdatesController = OptimisticUpdatesController(
            timeProvider: timeProvider,
            initialState: state,
            storage: storage
        )
        
        _Concurrency.Task { [weak self] in
            guard let self else {
                return
            }
            for behaviour in behaviours {
                await behaviour.setup(replica: self)
            }
        }
    }

    func observe(observerHost: any ReplicaObserverHost) async -> any ReplicaObserver {
        await ReplicaObserverImpl(
            observerHost: observerHost,
            replicaStateFlow: await stateFlow,
            replicaEventFlow: await eventFlow,
            observersController: observersController
        )
    }

    func refresh() async {
        await dataLoadingController.refresh()
    }
    
    func revalidate() async {
        await dataLoadingController.revalidate()
    }
    
    func getData(forceRefresh: Bool) async throws -> T {
        try await dataLoadingController.getData(forceRefresh: forceRefresh)
    }
    
    func setData(_ data: T) async {
        try? await dataChangingController.setData(data: data)
    }
    
    func mutateData(_ transform: @escaping @Sendable (T) -> T) async {
        try? await dataChangingController.mutateData(transform: transform)
    }
    
    func invalidate(mode: InvalidationMode) async {
        await freshnessController.invalidate()
        await dataLoadingController.refreshAfterInvalidation(invalidationMode: mode)
    }
    
    func makeFresh() async {
        await freshnessController.makeFresh()
    }
    
    func cancel() async {
        await dataLoadingController.cancel()
    }

    func clear(invalidationMode: InvalidationMode, removeFromStorage: Bool) async {
        await dataLoadingController.cancel()
        try? await clearingController.clear(removeFromStorage: removeFromStorage)
        await dataLoadingController.refreshAfterInvalidation(invalidationMode: invalidationMode)
    }
    
    func clearError() async {
        await clearingController.clearError()
    }
    
    func beginOptimisticUpdate(_ update: any OptimisticUpdate<T>) async {
        await optimisticUpdatesController.beginOptimisticUpdate(update: update)
    }
    
    func commitOptimisticUpdate(_ update: any OptimisticUpdate<T>) async {
        try? await optimisticUpdatesController.commitOptimisticUpdate(update: update)
    }
    
    func rollbackOptimisticUpdate(_ update: any OptimisticUpdate<T>) async {
        await optimisticUpdatesController.rollbackOptimisticUpdate(update: update)
    }
}
