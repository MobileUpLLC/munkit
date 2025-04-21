final class DndClassesCoordinator {
    weak var router: NavigationRouter?

    @MainActor func showClassOverview(for id: String) {
        Task {
            let controller = await ClassOverviewFactory.createClassOverviewController(id: id)

            router?.push(controller: controller, isAnimated: true)
        }
    }
}
