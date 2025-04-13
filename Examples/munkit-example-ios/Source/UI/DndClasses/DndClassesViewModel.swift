import Foundation
import MUNKit

final class DndClassesViewModel: ObservableObject {
    @Published private(set) var classItems: [DndClassesView.ViewItem]?

    private let coordinator: DndClassesCoordinator
    private let repository: DndClassesRepository
    private let replica: any Replica<ClassesListModel>
    private let observerStateStream: AsyncStream<Bool>
    private let observerContinuation: AsyncStream<Bool>.Continuation
    private var observerTask: Task<Void, Never>?

    init(coordinator: DndClassesCoordinator, replica: any Replica<ClassesListModel>, repository: DndClassesRepository) {
        self.coordinator = coordinator
        self.repository = repository
        self.replica = replica

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
    func clearData() {
        Task { await repository.clearData() }
    }

    @MainActor
    func invalidateData() {
        Task { await repository.invalidateData() }
    }

    @MainActor
    func startObserving() {
        print("\(self): startObserving")

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

                print("🐉 DndClassesViewModel: \(String(describing: viewItems))")
                self.classItems = viewItems
            }
            await observer.cancelObserving()
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
