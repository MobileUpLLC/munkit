import Foundation
import NetworkService

final class DndClassesViewModel: ObservableObject {
    @Published private(set) var classItems: [DndClassesView.ViewItem]?

    private let coordinator: DndClassesCoordinator
    private let replica: any Replica<ClassesListModel>
    private let observerStateStream: AsyncStream<Bool>
    private let observerContinuation: AsyncStream<Bool>.Continuation
    private var observerTask: Task<Void, Never>?

    init(coordinator: DndClassesCoordinator, replica: any Replica<ClassesListModel>) {
        self.coordinator = coordinator
        self.replica = replica

        let (observerActive, observerContinuation) = AsyncStream<Bool>.makeStream()
        
        self.observerStateStream = observerActive
        self.observerContinuation = observerContinuation
    }

    @MainActor
    func refresh() {
        Task { [weak self] in
            await self?.replica.refresh()
        }
    }

    @MainActor
    func startObserving() {
        Log.replica.debug(logEntry: .text("startObserving"))
        
        observerTask = Task { [weak self] in
            guard let self else {
                return
            }

            let observer = await replica.observe(observerActive: observerStateStream)
            
            self.observerContinuation.yield(true)

            guard let stateStream = await observer.replicaStateStream else {
                return
            }
            
            for await state in stateStream {
                let viewItems = state.data?.value.results.map {
                    DndClassesView.ViewItem(id: $0.index, name: $0.name)
                }

                Log.replica.debug(logEntry: .text("Получено состояние реплики: \(String(describing: viewItems))"))
                self.classItems = viewItems
            }
        }
    }

    @MainActor
    func handleTapOnItem(with id: String) {
        coordinator.showClassOverview(for: id)
    }

    deinit {
        observerContinuation.finish()
        observerTask = nil
    }
}
