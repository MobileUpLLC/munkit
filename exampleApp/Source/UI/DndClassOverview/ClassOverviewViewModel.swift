import Foundation

final class ClassOverviewViewModel: ObservableObject {
    @Published private(set) var viewItem: ClassOverviewView.ViewItem?

    private let coordinator: ClassOverviewCoordinator
    private let repository: DndRepository
    private let dndClassId: String

    init(id: String, coordinator: ClassOverviewCoordinator, repository: DndRepository) {
        self.dndClassId = id
        self.coordinator = coordinator
        self.repository = repository
    }

    @MainActor
    func getData() {
        Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let model = try await repository.getClassOverview(index: dndClassId)

                let viewItem: ClassOverviewView.ViewItem = .init(
                    name: model.name,
                    hitDie: "1d\(model.hitDie)",
                    savingThrows: model.savingThrows.map { $0.name },
                    proficiencies: model.proficiencies.map { $0.name },
                    description: model.spellcasting.map { $0.info.flatMap { $0.desc }.joined(separator: "\n") }
                )

                await MainActor.run {
                    self.viewItem = viewItem
                }
            } catch {
                print("error")
            }
        }
    }
}
