import Foundation

public actor ReplicaObserver<T> where T: Sendable {
    // MARK: - ReplicaStateStream
    public var replicaStateStream: AsyncStream<ReplicaState<T>>?
    private var replicaStateStreamContinuation: AsyncStream<ReplicaState<T>>.Continuation?
    private let externalReplicaStateStream: AsyncStream<ReplicaState<T>>
    private var replicaStateObservingTask: Task<Void, Never>?

    // MARK: - ReplicaEventStream
    var replicaEventStream: AsyncStream<ReplicaEvent<T>>?
    private var replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation?
    private let externalReplicaEventStream: AsyncStream<ReplicaEvent<T>>

    private let observerActive: AsyncStream<Bool>
    private var observerControllingTask: Task<Void, Never>?
    private let observersController: ObserversController<T>

    // MARK: - Initialization
    init(
        observerActive: AsyncStream<Bool>,
        externalStateStream: AsyncStream<ReplicaState<T>>,
        externalEventStream: AsyncStream<ReplicaEvent<T>>,
        observersController: ObserversController<T>
    ) async {
        self.observerActive = observerActive
        self.observersController = observersController
        self.externalReplicaStateStream = externalStateStream
        self.externalReplicaEventStream = externalEventStream
        self.replicaStateStreamContinuation = nil
        self.replicaEventStreamContinuation = nil
        self.replicaStateStream = nil
        self.replicaEventStream = nil

        self.replicaStateStream = AsyncStream<ReplicaState<T>> { self.replicaStateStreamContinuation = $0 }
        self.replicaEventStream = AsyncStream<ReplicaEvent<T>> { self.replicaEventStreamContinuation = $0 }

        await launchObserverControlling()
        await launchStateObserving()
    }

    func cancelObserving() async {
        observerControllingTask?.cancel()
        observerControllingTask = nil

        replicaStateObservingTask?.cancel()
        replicaStateObservingTask = nil
    }

    private func launchObserverControlling() async {
        let observerId = UUID()

        await observersController.onObserverAdded(observerId: observerId, active: true)

        observerControllingTask = Task {
            for await active in await observerActive {
                if active {
                    await observersController.onObserverActive(observerId: observerId)
                } else {
                    await observersController.onObserverInactive(observerId: observerId)
                }
            }

            await observersController.onObserverRemoved(observerId: observerId)
        }
    }

    private func launchStateObserving() async {
        replicaStateObservingTask = Task {
            for await replicaState in externalReplicaStateStream {
                replicaStateStreamContinuation?.yield(replicaState)
            }
        }
    }
}
