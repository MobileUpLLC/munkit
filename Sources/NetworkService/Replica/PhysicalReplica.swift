import Foundation

public protocol PhysicalReplica<T>: Replica where T: Sendable {
    var name: String { get }

    init(id: UUID, storage: (any Storage<T>)?, fetcher: @escaping Fetcher<T>, name: String) 
}

public actor PhysicalReplicaImpl<T: Sendable>: PhysicalReplica {
    private let id: UUID
    public let name: String
    private let storage: (any Storage<T>)?
    private let fetcher: Fetcher<T>
    private var replicaState: ReplicaState<T>

    private var observerStateStreams: [
        (stream: AsyncStream<ReplicaState<T>>, continuation: AsyncStream<ReplicaState<T>>.Continuation)
    ] = []

    private var observerEventStreams: [
        (stream: AsyncStream<ReplicaEvent<T>>, continuation: AsyncStream<ReplicaEvent<T>>.Continuation)
    ] = []

    private let observersControllerStateStream: (
        stream: AsyncStream<ReplicaState<T>>,
        continuation: AsyncStream<ReplicaState<T>>.Continuation
    )
    private let observersControllerEventStream: (
        stream: AsyncStream<ReplicaEvent<T>>,
        continuation: AsyncStream<ReplicaEvent<T>>.Continuation
    )
    private let loaderControllerStateStream: (
        stream: AsyncStream<ReplicaState<T>>,
        continuation: AsyncStream<ReplicaState<T>>.Continuation
    )
    private let loaderControllerEventStream: (
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
        self.observersControllerStateStream = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.observersControllerEventStream = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.loaderControllerStateStream = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.loaderControllerEventStream = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.observersController = nil
        self.dataLoadingController = nil

        Task {
            await setupControllers()
        }
    }

    private func setupControllers() async {
        self.observersController = ObserversController(
            replicaState: replicaState,
            replicaStateStream: observersControllerStateStream.stream,
            replicaEventStreamContinuation: observersControllerEventStream.continuation
        )

        let dataLoader = DataLoader(storage: storage, fetcher: fetcher)
        self.dataLoadingController = DataLoadingController(
            replicaState: replicaState,
            replicaStateStream: loaderControllerStateStream.stream,
            replicaEventStreamContinuation: loaderControllerEventStream.continuation,
            dataLoader: dataLoader
        )

        Task {
            for await newReplicaEvent in loaderControllerEventStream.stream {
                handleReplicaEvent(newReplicaEvent)
            }
        }

        Task {
            for await newReplicaEvent in observersControllerEventStream.stream {
                handleReplicaEvent(newReplicaEvent)
            }
        }
    }

    private func updateReplicaState(_ newReplicaState: ReplicaState<T>) {
        Log.replica.debug(logEntry: .text("💾 Replica \(self) обновила состояние: \(newReplicaState)"))
        replicaState = newReplicaState

        let stateStreams = observerStateStreams
            + [loaderControllerStateStream, observersControllerStateStream]

        stateStreams.forEach { $0.continuation.yield(replicaState) }
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
        let stateStream = AsyncStream<ReplicaState<T>>.makeStream()
        observerStateStreams.append(stateStream)

        let eventStreams = AsyncStream<ReplicaEvent<T>>.makeStream()
        observerEventStreams.append(eventStreams)

        return await ReplicaObserver<T>(
            observerActive: observerActive,
            replicaStateStream: stateStream.stream,
            externalEventStream: eventStreams.stream,
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
