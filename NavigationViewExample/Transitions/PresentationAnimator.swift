import UIKit
import MapboxNavigation

class PresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? ViewController,
              let toViewController = transitionContext.viewController(forKey: .to) as? NavigationViewController else {
            transitionContext.completeTransition(false)
            return
        }
        
        // Replace already exisiting `NavigationMapView` from `NavigationViewController` with `NavigationMapView`
        // that was used in `ViewController`.
        toViewController.navigationMapView = fromViewController.navigationView.navigationMapView
        
        transitionContext.containerView.addSubview(toViewController.view)
        transitionContext.completeTransition(true)
    }
}
