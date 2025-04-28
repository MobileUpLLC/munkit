import UIKit
final class RootCoordinator {
    weak var router: NavigationRouter?

    @MainActor func showDndClasses() {
        Task {
            let controller = await DndClassesFactory.createDndClassesController()

            router?.push(controller: controller, isAnimated: true)
        }
    }
}
