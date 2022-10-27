import UIKit
import MapboxMaps
import MapboxNavigation

class DismissalAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? NavigationViewController,
              let navigationMapView = fromViewController.navigationMapView,
              let toViewController = transitionContext.viewController(forKey: .to) as? ViewController else {
            transitionContext.completeTransition(false)
            return
        }
        
        // `NavigationMapView` should be transfered back from `NavigationViewController` to `ViewController`.
        toViewController.navigationView.navigationMapView = navigationMapView
        
        transitionContext.containerView.addSubview(toViewController.view)
        transitionContext.completeTransition(true)
    }
}
