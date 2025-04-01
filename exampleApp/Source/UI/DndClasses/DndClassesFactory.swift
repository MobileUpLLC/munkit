import UIKit

enum DndClassesFactory {
    @MainActor static func createDndClassesController() -> UINavigationController {
        let repository = DndClassesRepository()
        let coordinator = DndClassesCoordinator()
        let viewModel = DndClassesViewModel(coordinator: coordinator, repository: repository)
        let controller = DndClassesController(viewModel: viewModel)
        coordinator.router = controller
        
        return UINavigationController(rootViewController: controller)
    }
}
