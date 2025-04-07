import Foundation

public actor ReplicaObserver<T> where T: Sendable {
    // MARK: - ReplicaStateStream
    public let replicaStateStream: AsyncStream<ReplicaState<T>>
    private var replicaStateStreamContinuation: AsyncStream<ReplicaState<T>>.Continuation?
    private var replicaStateObservingTask: Task<Void, Never>?

    // MARK: - ReplicaEventStream
    var replicaEventStream: AsyncStream<ReplicaEvent<T>>?
    private var replicaEventStreamContinuation: AsyncStream<ReplicaEvent<T>>.Continuation?

    private let observerActive: AsyncStream<Bool>
    private var observerControllingTask: Task<Void, Never>?
    private let observersController: ReplicaObserversController<T>

    // MARK: - Initialization
    init(
        observerActive: AsyncStream<Bool>,
        replicaStateStream: AsyncStream<ReplicaState<T>>,
        externalEventStream: AsyncStream<ReplicaEvent<T>>,
        observersController: ReplicaObserversController<T>
    ) async {
        self.observerActive = observerActive
        self.observersController = observersController
        self.replicaStateStream = replicaStateStream
        self.replicaEventStreamContinuation = nil
        self.replicaEventStream = nil

        self.replicaEventStream = AsyncStream<ReplicaEvent<T>> { self.replicaEventStreamContinuation = $0 }

        await launchObserverControlling()
    }

    func cancelObserving() async {
        observerControllingTask?.cancel()
        observerControllingTask = nil

        replicaStateObservingTask?.cancel()
        replicaStateObservingTask = nil
    }

    /// отслеживает активность наблюдателя
    private func launchObserverControlling() async {
        let observerId = UUID()

        await observersController.onObserverAdded(observerId: observerId, isObserverActive: true)

        observerControllingTask = Task {
            for await active in observerActive {
                if active {
                    await observersController.onObserverActive(observerId: observerId)
                } else {
                    await observersController.onObserverInactive(observerId: observerId)
                }
            }

            await observersController.onObserverRemoved(observerId: observerId)
        }
    }
}
