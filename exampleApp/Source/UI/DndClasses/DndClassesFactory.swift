import UIKit
import MUNKit

enum DndClassesFactory {
    @MainActor static func createDndClassesController() async -> DndClassesController {
        let repository = await DndClassesRepository()
        let coordinator = DndClassesCoordinator()
        let viewModel = DndClassesViewModel(coordinator: coordinator, replica: repository.replica)
        let controller = DndClassesController(viewModel: viewModel)
        coordinator.router = controller

        return controller
    }
}
