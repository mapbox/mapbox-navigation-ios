import UIKit
import MapboxNavigation

class PresentationAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? PreviewViewController,
              let toViewController = transitionContext.viewController(forKey: .to) as? NavigationViewController else {
            transitionContext.completeTransition(false)
            return
        }
        
        // Replace default `NavigationMapView` in `NavigationViewController` with `NavigationMapView`
        // that was used in `PreviewViewController`.
        toViewController.navigationMapView = fromViewController.navigationMapView
        
        transitionContext.containerView.addSubview(toViewController.view)
        transitionContext.completeTransition(true)
    }
}
