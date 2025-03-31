import UIKit

enum ___FILEBASENAME___ {
    static func create___VARIABLE_productName:identifier___Controller() -> ___VARIABLE_productName:identifier___Controller {
        let coordinator = ___VARIABLE_productName:identifier___Coordinator()
        let viewModel = ___VARIABLE_productName:identifier___ViewModel(coordinator: coordinator)
        let controller = ___VARIABLE_productName:identifier___Controller(viewModel: viewModel)
        coordinator.router = controller
        
        return controller
    }
}
