import UIKit
import munkit_example_core

enum ClassOverviewFactory {
    @MainActor static func createClassOverviewController(id: String) -> ClassOverviewController {
        let coordinator = ClassOverviewCoordinator()
        let repository = DNDClassOverviewRepository()

        let viewModel = ClassOverviewViewModel(id: id, coordinator: coordinator, repository: repository)
        let controller = ClassOverviewController(viewModel: viewModel)
        coordinator.router = controller
        
        return controller
    }
}
