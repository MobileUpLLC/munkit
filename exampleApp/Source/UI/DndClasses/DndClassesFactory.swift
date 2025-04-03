import UIKit
import NetworkService

enum DndClassesFactory {
    @MainActor static func createDndClassesController() -> UINavigationController {
        let repository = DndClassesRepository()
        let replica = PhysicalReplica<ClassesListModel>(storage: nil, fetcher: repository)
        let coordinator = DndClassesCoordinator()
        let viewModel = DndClassesViewModel(coordinator: coordinator, replica: replica)
        let controller = DndClassesController(viewModel: viewModel)
        coordinator.router = controller
        
        return UINavigationController(rootViewController: controller)
    }
}
