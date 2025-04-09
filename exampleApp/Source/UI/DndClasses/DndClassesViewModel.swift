import Foundation
import MUNKit

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

//        Task { [weak self] in
//            self?.replica = await DndClassesRepository.shared.getReplica()
//        }

        let (observerActive, observerContinuation) = AsyncStream<Bool>.makeStream()
        
        self.observerStateStream = observerActive
        self.observerContinuation = observerContinuation
    }

    @MainActor
    func refresh() async {
        await replica.refresh()
    }

    @MainActor
    func revalidate() async {
        await replica.revalidate()
    }

    @MainActor
    func startObserving() {
        Log.replica.debug(logEntry: .text("\(self): startObserving"))

        observerTask = Task { [weak self] in
            guard let self else {
                return
            }

            let observer = await replica.observe(observerActive: observerStateStream)

            self.observerContinuation.yield(true)
            
            for await state in await observer.replicaStateStream {
                let viewItems = state.data?.value.results.map {
                    DndClassesView.ViewItem(id: $0.index, name: $0.name)
                }

                Log.replica.debug(logEntry:.text("🐉 DndClassesViewModel: \(String(describing: viewItems))"))
                self.classItems = viewItems
            }
        }
    }

    @MainActor
    func handleTapOnItem(with id: String) {
        coordinator.showClassOverview(for: id)
    }

    deinit {
        print("deinit DndClassesViewModel")
    }

    func deinitObserver() {
        observerContinuation.yield(false)
        observerTask?.cancel()
        observerTask = nil
    }
}
