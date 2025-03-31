import UIKit

protocol NavigationRouter: AnyObject {
    func push(controller: UIViewController, isAnimated: Bool)
    func pop(isAnimated: Bool)
    func pop(to: AnyClass, isAnimated: Bool)
    func popToRoot(isAnimated: Bool)
}

extension UIViewController: @preconcurrency NavigationRouter {
    func push(controller: UIViewController, isAnimated: Bool = true) {
        navigationController?.pushViewController(controller, animated: isAnimated)
    }
    
    func pop(isAnimated: Bool = true) {
        navigationController?.popViewController(animated: isAnimated)
    }
    
    func pop(to controllerClass: AnyClass, isAnimated: Bool = true) {
        if let controller = navigationController?.viewControllers.last(where: { $0.isKind(of: controllerClass) }) {
            navigationController?.popToViewController(controller, animated: isAnimated)
        } else {
            pop()
        }
    }
    
    func popToRoot(isAnimated: Bool = true) {
        navigationController?.popToRootViewController(animated: isAnimated)
    }
 }
