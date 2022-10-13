import UIKit
import MapboxNavigation

class DismissalAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? NavigationViewController,
              let navigationMapView = fromViewController.navigationMapView,
              let toViewController = transitionContext.viewController(forKey: .to) as? PreviewViewController else {
            transitionContext.completeTransition(false)
            return
        }
        
        // Transfer `NavigationMapView` that was used in `NavigationViewController` back to
        // `PreviewViewController`.
        toViewController.navigationMapView = navigationMapView
        
        transitionContext.containerView.addSubview(toViewController.view)
        transitionContext.completeTransition(true)
    }
}
