import UIKit
import MapboxNavigation

class DismissalAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? NavigationViewController,
              let toViewController = transitionContext.viewController(forKey: .to) as? PreviewViewController else {
            transitionContext.completeTransition(false)
            return
        }
        
        transitionContext.containerView.addSubview(toViewController.view)
        transitionContext.completeTransition(true)
        
        toViewController.navigationView.navigationMapView = fromViewController.navigationView.navigationMapView
        toViewController.setupNavigationViewportDataSource()
        toViewController.setupPassiveLocationManager()
        toViewController.navigationView.navigationMapView.removeArrow()
        toViewController.fitCamera(to: fromViewController.routeResponse)
        toViewController.navigationView.bottomBannerContainerView.show()
    }
}
