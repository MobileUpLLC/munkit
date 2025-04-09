import Foundation

public protocol PhysicalReplica<T>: Replica where T: Sendable {
    var name: String { get }

    init(id: UUID, storage: (any Storage<T>)?, fetcher: @escaping Fetcher<T>, name: String)
}

public actor PhysicalReplicaImplementation<T: Sendable>: PhysicalReplica {
    private let identifier: UUID
    public let name: String
    private let storage: (any Storage<T>)?
    private let fetcher: Fetcher<T>
    private var currentReplicaState: ReplicaState<T>

    private var observerStateStreamPairs: [AsyncStreamBundle<ReplicaState<T>>] = []
    private var observerEventStreamPairs: [AsyncStreamBundle<ReplicaEvent<T>>] = []

    private let observersControllerStateStreamPair: AsyncStreamBundle<ReplicaState<T>>
    private let observersControllerEventStreamPair: AsyncStreamBundle<ReplicaEvent<T>>
    private let loadingControllerStateStreamPair: AsyncStreamBundle<ReplicaState<T>>
    private let loadingControllerEventStreamPair: AsyncStreamBundle<ReplicaEvent<T>>

    private var observersController: ReplicaObserversController<T>?
    private var loadingController: ReplicaLoadingController<T>?

    public init(id: UUID = UUID(), storage: (any Storage<T>)?, fetcher: @escaping Fetcher<T>, name: String) {
        self.identifier = id
        self.name = name
        self.storage = storage
        self.fetcher = fetcher
        self.currentReplicaState = ReplicaState<T>.createEmpty(hasStorage: storage != nil)
        self.observersControllerStateStreamPair = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.observersControllerEventStreamPair = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.loadingControllerStateStreamPair = AsyncStream.makeStream(of: ReplicaState<T>.self)
        self.loadingControllerEventStreamPair = AsyncStream.makeStream(of: ReplicaEvent<T>.self)
        self.observersController = nil
        self.loadingController = nil

        Task {
            await initializeControllers()
        }
    }

    private func initializeControllers() async {
        self.observersController = ReplicaObserversController(
            replicaState: currentReplicaState,
            replicaStateStream: observersControllerStateStreamPair.stream,
            replicaEventStreamContinuation: observersControllerEventStreamPair.continuation
        )

        let dataLoader = DataLoader(storage: storage, fetcher: fetcher)
        self.loadingController = ReplicaLoadingController(
            replicaState: currentReplicaState,
            replicaStateStream: loadingControllerStateStreamPair.stream,
            replicaEventStreamContinuation: loadingControllerEventStreamPair.continuation,
            dataLoader: dataLoader
        )

        Task {
            for await event in loadingControllerEventStreamPair.stream {
                processReplicaEvent(event)
            }
        }

        Task {
            for await event in observersControllerEventStreamPair.stream {
                processReplicaEvent(event)
            }
        }
    }

    private func updateState(_ newState: ReplicaState<T>) {
        print("💾 Replica \(self) обновила состояние: \(newState)")
        currentReplicaState = newState

        let allStateStreamPairs = observerStateStreamPairs
            + [loadingControllerStateStreamPair, observersControllerStateStreamPair]

        allStateStreamPairs.forEach { $0.continuation.yield(currentReplicaState) }
    }

    private func processReplicaEvent(_ event: ReplicaEvent<T>) {
        switch event {
        case .loading(let loadingEvent):
            switch loadingEvent {
            case .loadingStarted(let state):
                updateState(state)
            case .dataFromStorageLoaded(let state):
                updateState(state)
            case .loadingFinished(let state):
                switch state {
                case .success(let state), .canceled(let state), .error(let state):
                    updateState(state)
                }
            }
        case .freshness:
            break
        case .cleared:
            fatalError()
        case .observerCountChanged(let observingState):
            let previousState = currentReplicaState
            updateState(currentReplicaState.copy(observingState: observingState))

            if observingState.activeObserverIds.count > previousState.observingState.activeObserverIds.count {
                Task { await revalidate() }
            }
        }
    }

    public func observe(observerActive: AsyncStream<Bool>) async -> ReplicaObserver<T> {
        let stateStreamPair = AsyncStream<ReplicaState<T>>.makeStream()
        observerStateStreamPairs.append(stateStreamPair)

        let eventStreamPair = AsyncStream<ReplicaEvent<T>>.makeStream()
        observerEventStreamPairs.append(eventStreamPair)

        return await ReplicaObserver<T>(
            observerActive: observerActive,
            replicaStateStream: stateStreamPair.stream,
            externalEventStream: eventStreamPair.stream,
            observersController: observersController!
        )
    }

    public func refresh() async {
        await loadingController!.refresh()
    }

    public func revalidate() async {
        await loadingController!.revalidate()
    }

    public func getData(forceRefresh: Bool) async throws -> T {
        try await loadingController!.getData(forceRefresh: forceRefresh)
    }

    func cancel() async {
        await loadingController!.cancel()
    }
}
