final class DndClassesCoordinator {
    weak var router: NavigationRouter?

    @MainActor func showClassOverview(for id: String) {
        let controller = ClassOverviewFactory.createClassOverviewController(id: id)

        router?.push(controller: controller, isAnimated: true)
    }
}
