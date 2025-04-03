import Foundation

public protocol PhysicalReplica<T>: Replica {
    associatedtype T: Sendable

    var name: String { get }

    init(id: UUID, storage: (any Storage<T>)?, fetcher: @escaping Fetcher<T>, name: String) 
}

public actor PhysicalReplicaImpl<T: Sendable>: PhysicalReplica {
    private let id: UUID
    public let name: String
    private let storage: (any Storage<T>)?
    private let fetcher: Fetcher<T>
    private var replicaState: ReplicaState<T>

    private var replicaStateStreamContinuation: AsyncStream<ReplicaState<T>>.Continuation
    private var replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation

    private let replicaStateStream: AsyncStream<ReplicaState<T>>
    private let replicaEventStream: AsyncStream<ReplicaEvent<T>>

    private let observersController: ObserversController<T>
    private let dataLoadingController: DataLoadingController<T>

    public init(id: UUID = UUID(), storage: (any Storage<T>)?, fetcher: @escaping Fetcher<T>, name: String) {
        self.id = id
        self.name = name
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

        Task { [weak self] in
            await self?.listenReplicaEvent()
        }
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

    /// взято из createBehavioursForReplicaSettings оригинальной реплики
    private func listenReplicaEvent() async {
        for await event in await self.replicaEventStream {
            Log.replica.debug(logEntry: .text("\(self): Получено событие \(event)"))

            if case .observerCountChanged(let info) = event,
               info.activeCount > info.previousActiveCount {
                await revalidate()
            }
        }
    }
}
