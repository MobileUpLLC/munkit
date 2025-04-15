import Foundation
import munkit
import munkit_example_core

final class DndClassesViewModel: ObservableObject {
    @Published private(set) var classItems: [DndClassesView.ViewItem]?

    private let coordinator: DndClassesCoordinator
    private let repository: DNDClassesRepository
    private let replica: any Replica<DNDClassesListModel>
    private let observerStateStream: AsyncStream<Bool>
    private let observerContinuation: AsyncStream<Bool>.Continuation
    private var observerTask: Task<Void, Never>?

    init(
        coordinator: DndClassesCoordinator,
        replica: any Replica<DNDClassesListModel>,
        repository: DNDClassesRepository
    ) {
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
    func setData() {
        Task {
            let mockClassesList = DNDClassesListModel(
                results: [
                    DNDClassModel(
                        index: "barbarian",
                        name: "Barbarian",
                        // swiftlint:disable:next force_unwrapping
                        url: URL(string: "https://www.dnd5eapi.co/api/classes/barbarian")!
                    ),
                    DNDClassModel(
                        index: "bard",
                        name: "Bard",
                        // swiftlint:disable:next force_unwrapping
                        url: URL(string: "https://www.dnd5eapi.co/api/classes/bard")!
                    )
                ]
            )
            await repository.setData(data: mockClassesList)
        }
    }

    @MainActor
    func mutateData() {
        Task {
            await repository.mutateData { @Sendable data in
                var mutatedData = data
                mutatedData.results.removeLast()
                return mutatedData
            }
        }
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
                let viewItems = state.data?.valueWithOptimisticUpdates.results.map {
                    DndClassesView.ViewItem(id: $0.index, name: $0.name, isLiked: $0.isLiked)
                }

                print("🐉 DndClassesViewModel: \(String(describing: viewItems))")
                self.classItems = viewItems
            }
            await observer.cancelObserving()
        }
    }

    @MainActor
    func setLike(index: String) {
        guard
            let itemIndex = classItems?.firstIndex(where: { $0.id == index }),
            let isLiked = classItems?[itemIndex].isLiked
        else {
            return
        }
        Task {
            await repository.setLike(index: index, liked: !isLiked)
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
