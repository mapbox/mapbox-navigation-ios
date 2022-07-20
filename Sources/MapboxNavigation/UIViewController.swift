import UIKit

extension UIViewController {
    
    func embed(_ viewController: UIViewController,
               in view: UIView,
               constrainedBy constraints: ((UIViewController, UIViewController) -> [NSLayoutConstraint])? = nil) {
        viewController.view.frame = view.bounds
        view.addSubview(viewController.view)
        addChild(viewController)
        
        if let childConstraints = constraints?(self, viewController) {
            self.view.addConstraints(childConstraints)
        }
        
        viewController.didMove(toParent: self)
    }
}
