import UIKit

enum RootFactory {
    @MainActor static func createRootController() -> UINavigationController {
        let coordinator = RootCoordinator()
        let viewModel = RootViewModel(coordinator: coordinator)
        let controller = RootController(viewModel: viewModel)
        coordinator.router = controller
        
        return UINavigationController(rootViewController: controller)
    }
}
