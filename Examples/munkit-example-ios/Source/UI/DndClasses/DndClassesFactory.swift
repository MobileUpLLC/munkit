import UIKit
import munkit_example_core

enum DndClassesFactory {
    @MainActor static func createDndClassesController() async -> DndClassesController {
        let repository = await DNDClassesRepository(networkService: MobileService.shared.networkService)
        let coordinator = DndClassesCoordinator()
        let viewModel = await DndClassesViewModel(
            coordinator: coordinator,
            replica: repository.replica,
            repository: repository
        )
        let controller = DndClassesController(viewModel: viewModel)
        coordinator.router = controller

        return controller
    }
}
