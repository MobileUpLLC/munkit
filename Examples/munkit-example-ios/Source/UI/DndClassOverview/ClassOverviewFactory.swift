import UIKit
import munkit_example_core
import munkit

enum ClassOverviewFactory {
    @MainActor static func createClassOverviewController(id: String) async -> ClassOverviewController {
        let repository = await DNDClassOverviewRepository(networkService: MobileService.shared.networkService)

        let replica = await repository.replica.withKey(id)
        let viewModel = ClassOverviewViewModel(
            id: id,
            replica: replica,
            repository: repository
        )
        let controller = ClassOverviewController(viewModel: viewModel)
        
        return controller
    }
}
