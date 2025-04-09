import UIKit

enum ClassOverviewFactory {
    @MainActor static func createClassOverviewController(id: String) -> ClassOverviewController {
        let coordinator = ClassOverviewCoordinator()
        let repository = DndClassOverviewRepository()

        let viewModel = ClassOverviewViewModel(id: id, coordinator: coordinator, repository: repository)
        let controller = ClassOverviewController(viewModel: viewModel)
        coordinator.router = controller
        
        return controller
    }
}
