import UIKit

protocol RootRouter: AnyObject {
    func showApplicationRoot(controller: UIViewController, animated: Bool)
}

// extension UIViewController: RootRouter {
//    private enum Constants {
//        static let fadeAnimationDuration = 0.25
//    }
//    
//    func showApplicationRoot(controller: UIViewController, animated: Bool) {
//        guard let window = UIApplication.shared.keyWindow else {
//            return
//        }
//        
//        let snapshotView = window.snapshotView(afterScreenUpdates: true)
//                
//        window.rootViewController = controller
//        
//        if let snapshotView = snapshotView, animated {
//            window.addSubview(snapshotView)
//            
//            UIView.animate(
//                withDuration: Constants.fadeAnimationDuration,
//                delay: .zero,
//                options: [.curveEaseInOut],
//                animations: {
//                    snapshotView.alpha = .zero
//                },
//                completion: { _ in
//                    snapshotView.removeFromSuperview()
//                }
//            )
//        }
//    }
// }
