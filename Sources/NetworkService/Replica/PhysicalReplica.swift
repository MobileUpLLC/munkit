import Foundation

actor PhysicalReplica<T: Sendable>: Replica {
    private let id: UUID

    private let storage: (any Storage<T>)?
    private let fetcher: any Fetcher<T>
    private var replicaState: ReplicaState<T>

    private var replicaStateStreamContinuation: AsyncStream<ReplicaState<T>>.Continuation
    private var replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation

    private let replicaStateStream: AsyncStream<ReplicaState<T>>
    private let replicaEventStream: AsyncStream<ReplicaEvent<T>>

    private let observersController: ObserversController<T>
    private let dataLoadingController: DataLoadingController<T>

    init(id: UUID = UUID(), storage: (any Storage<T>)?, fetcher: any Fetcher<T>) async {
        self.id = id
        self.storage = storage
        self.fetcher = fetcher
        self.replicaState = ReplicaState<T>.createEmpty(hasStorage: storage != nil)

        let (stateStream, stateContinuation) = AsyncStream.makeStream(of: ReplicaState<T>.self)
        replicaStateStream = stateStream
        replicaStateStreamContinuation = stateContinuation

        let (eventStream, eventContinuation) = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        replicaEventStream = eventStream
        replicaEventStreamContinuation = eventContinuation

        self.observersController = await ObserversController(
            replicaState: replicaState,
            replicaStateStream: replicaStateStream,
            replicaEventStreamContinuation: replicaEventStreamContinuation
        )

        let dataLoader = DataLoader(storage: storage, fetcher: fetcher)
        self.dataLoadingController = DataLoadingController(
            replicaState: replicaState,
            replicaEventStreamContinuation: replicaEventStreamContinuation,
            dataLoader: dataLoader
        )
    }

    func observe(observerHost: ReplicaObserverHost) async -> ReplicaObserver<T> {
        await ReplicaObserver<T>(
            observerHost: observerHost,
            externalStateStream: replicaStateStream,
            externalEventStream: replicaEventStream,
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

    func cancel() async {
        await dataLoadingController.cancel()
    }
}
