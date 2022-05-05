import UIKit
@_spi(Experimental) import MapboxNavigation

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
        
        // Replace already exisiting `NavigationMapView` from `NavigationViewController` with `NavigationMapView`
        // that was used in `PreviewViewController`.
        toViewController.navigationView.navigationMapView = fromViewController.navigationView.navigationMapView
        
        // Hide top and bottom container views before animating their presentation.
        toViewController.navigationView.topBannerContainerView.isHidden = true
        toViewController.navigationView.topBannerContainerView.show()
        
        toViewController.navigationView.bottomBannerContainerView.isHidden = true
        toViewController.navigationView.bottomBannerContainerView.show()
        
        transitionContext.containerView.addSubview(toViewController.view)
        transitionContext.completeTransition(true)
    }
}
