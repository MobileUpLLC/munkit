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

    private let replicaStateStream: (
        stream: AsyncStream<ReplicaState<T>>,
        continuation: AsyncStream<ReplicaState<T>>.Continuation
    )
    private let replicaEventStream: (
        stream: AsyncStream<ReplicaEvent<T>>,
        continuation: AsyncStream<ReplicaEvent<T>>.Continuation
    )

    private var observersController: ObserversController<T>?
    private var dataLoadingController: DataLoadingController<T>?

    public init(id: UUID = UUID(), storage: (any Storage<T>)?, fetcher: @escaping Fetcher<T>, name: String) {
        self.id = id
        self.name = name
        self.storage = storage
        self.fetcher = fetcher
        self.replicaState = ReplicaState<T>.createEmpty(hasStorage: storage != nil)
        self.replicaStateStream = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.replicaEventStream = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.observersController = nil
        self.dataLoadingController = nil

        Task {
            await setupControllers()
        }
    }

    private func setupControllers() async {
        let controllersReplicaStateStream = AsyncStream.makeStream(of: ReplicaState<T>.self)
        let controllersReplicaEventStream = AsyncStream.makeStream(of: ReplicaEvent<T>.self)

        self.observersController = ObserversController(
            replicaState: replicaState,
            replicaStateStream: replicaStateStream.stream,
            replicaEventStreamContinuation: controllersReplicaEventStream.continuation
        )

        let dataLoader = DataLoader(storage: storage, fetcher: fetcher)
        self.dataLoadingController = DataLoadingController(
            replicaState: replicaState,
            replicaStateStream: replicaStateStream.stream,
            replicaEventStreamContinuation: controllersReplicaEventStream.continuation,
            dataLoader: dataLoader
        )

        for await newReplicaEvent in controllersReplicaEventStream.stream {
            handleReplicaEvent(newReplicaEvent)
        }
    }

    private func updateReplicaState(_ newReplicaState: ReplicaState<T>) {
        Log.replica.debug(logEntry: .text("💾 Replica \(self) обновила состояние: \(newReplicaState)"))
        replicaState = newReplicaState
        replicaStateStream.continuation.yield(replicaState)
    }

    private func handleReplicaEvent(_ newReplicaEvent: ReplicaEvent<T>) {
        switch newReplicaEvent {
        case .loading(let loadingEvent):
            switch loadingEvent {
            case .loadingStarted(let state):
                updateReplicaState(state)
            case .dataFromStorageLoaded(let state):
                updateReplicaState(state)
            case .loadingFinished(let state):
                switch state {
                case .success(let state), .canceled(let state), .error(let state):
                    updateReplicaState(state)
                }
            }
        case .freshness(let freshnessEvent):
            break
        case .cleared:
            fatalError()
        case .observerCountChanged(let observingState):
            let previousReplicaState = replicaState

            updateReplicaState(replicaState.copy(observingState: observingState))

            if observingState.activeObserverIds.count > previousReplicaState.observingState.activeObserverIds.count {
                Task { await revalidate() }
            }
        }
    }

    public func observe(observerActive: AsyncStream<Bool>) async -> ReplicaObserver<T> {
        await ReplicaObserver<T>(
            observerActive: observerActive,
            replicaStateStream: replicaStateStream.stream,
            externalEventStream: replicaEventStream.stream,
            observersController: observersController!
        )
    }

    public func refresh() async {
        await dataLoadingController!.refresh()
    }

    public func revalidate() async {
        await dataLoadingController!.revalidate()
    }

    public func getData(forceRefresh: Bool) async throws -> T {
        try await dataLoadingController!.getData(forceRefresh: forceRefresh)
    }

    func cancel() async {
        await dataLoadingController!.cancel()
    }
}
