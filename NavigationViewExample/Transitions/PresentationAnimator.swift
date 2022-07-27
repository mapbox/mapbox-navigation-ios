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
        toViewController.navigationView.navigationMapView = fromViewController.navigationView.navigationMapView
        
        // Switch navigation camera to active navigation mode.
        toViewController.navigationMapView?.navigationCamera.viewportDataSource = NavigationViewportDataSource(toViewController.navigationView.navigationMapView.mapView,
                                                                                                               viewportDataSourceType: .active)
        toViewController.navigationMapView?.navigationCamera.follow()
        
        // Change user location style to show view that represents user’s location and course on the map.
        toViewController.navigationMapView?.userLocationStyle = .courseView()
        
        // Render part of the route that has been traversed with full transparency, to give the illusion of a disappearing route.
        // FIXME: After `NavigationViewController` dismissal route is not correctly updated.
        // toViewController.routeLineTracksTraversal = true
        
        // Hide top and bottom container views before animating their presentation.
        toViewController.navigationView.bottomBannerContainerView.hide(animated: false)
        toViewController.navigationView.topBannerContainerView.hide(animated: false)
        
        // Hide `WayNameView`, `FloatingStackView` and `SpeedLimitView` to smoothly present them.
        toViewController.navigationView.wayNameView.alpha = 0.0
        toViewController.navigationView.floatingStackView.alpha = 0.0
        toViewController.navigationView.speedLimitView.alpha = 0.0
        
        // Animate top and bottom banner views presentation.
        toViewController.navigationView.bottomBannerContainerView.show(duration: 1.0,
                                                                       animations: {
            toViewController.navigationView.wayNameView.alpha = 1.0
            toViewController.navigationView.floatingStackView.alpha = 1.0
            toViewController.navigationView.speedLimitView.alpha = 1.0
        })
        toViewController.navigationView.topBannerContainerView.show(duration: 1.0)
        
        transitionContext.containerView.addSubview(toViewController.view)
        transitionContext.completeTransition(true)
    }
}
