import UIKit

extension UIViewController {
    
    func embed(_ viewController: UIViewController, in view: UIView) {
        viewController.view.frame = view.bounds
        view.addSubview(viewController.view)
        addChild(viewController)
        
        viewController.didMove(toParent: self)
    }
}
