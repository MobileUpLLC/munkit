import Foundation

public actor PhysicalReplica<T: Sendable>: Replica {
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

    public init(id: UUID = UUID(), storage: (any Storage<T>)?, fetcher: any Fetcher<T>) {
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

        self.observersController = ObserversController(
            replicaState: replicaState,
            replicaStateStream: replicaStateStream,
            replicaEventStreamContinuation: replicaEventStreamContinuation
        )

        let dataLoader = DataLoader(storage: storage, fetcher: fetcher)
        self.dataLoadingController = DataLoadingController(
            replicaState: replicaState,
            replicaStateStreamContinuation: replicaStateStreamContinuation,
            replicaEventStreamContinuation: replicaEventStreamContinuation,
            dataLoader: dataLoader
        )
    }
    
    public func observe(observerActive: AsyncStream<Bool>) async -> ReplicaObserver<T> {
        await ReplicaObserver<T>(
            observerActive: observerActive,
            externalStateStream: replicaStateStream,
            externalEventStream: replicaEventStream,
            observersController: observersController
        )
    }

    public func refresh() async {
        await dataLoadingController.refresh()
    }

    public func revalidate() async {
        await dataLoadingController.revalidate()
    }

    public func getData(forceRefresh: Bool) async throws -> T {
        try await dataLoadingController.getData(forceRefresh: forceRefresh)
    }

    func cancel() async {
        await dataLoadingController.cancel()
    }
}
