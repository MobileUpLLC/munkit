import Foundation

final class DndClassesViewModel: ObservableObject {
    @Published private(set) var classItems: [DndClassesView.ViewItem]?

    private let coordinator: DndClassesCoordinator
    private let repository: DndRepository

    init(coordinator: DndClassesCoordinator, repository: DndRepository) {
        self.coordinator = coordinator
        self.repository = repository

     //   getData()
    }

    @MainActor func handleTapOnItem(with id: String) {
        coordinator.showClassOverview(for: id)
    }

    @MainActor
    func getData() {
        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let classes = try await repository.getDndClasses()
                let viewItems = classes.results.map { DndClassesView.ViewItem(id: $0.index, name: $0.name) }

                await MainActor.run {
                    self.classItems = viewItems
                }
            } catch {
                print("error")
            }
        }
    }
}
