import UIKit
import MapboxMaps
import MapboxNavigation

class DismissalAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.0
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromViewController = transitionContext.viewController(forKey: .from) as? NavigationViewController,
              let toViewController = transitionContext.viewController(forKey: .to) as? ViewController else {
            transitionContext.completeTransition(false)
            return
        }
        
        // Hide top and bottom banner containers.
        fromViewController.navigationView.topBannerContainerView.hide(duration: 1.0)
        fromViewController.navigationView.bottomBannerContainerView.hide(duration: 1.0,
                                                                         animations: {
            fromViewController.navigationView.wayNameView.alpha = 0.0
            fromViewController.navigationView.floatingStackView.alpha = 0.0
            fromViewController.navigationView.speedLimitView.alpha = 0.0
        },
                                                                         completion: { _ in
            transitionContext.containerView.addSubview(toViewController.view)
            
            toViewController.navigationView.navigationMapView = fromViewController.navigationView.navigationMapView
            
            toViewController.navigationView.navigationMapView.userLocationStyle = .puck2D()
            
            if let routes = toViewController.routes {
                let cameraOptions = CameraOptions(bearing: 0.0, pitch: 0.0)
                toViewController.navigationView.navigationMapView.showcase(routes,
                                                                           routesPresentationStyle: .all(shouldFit: true, cameraOptions: cameraOptions),
                                                                           animated: true,
                                                                           duration: 1.0) { _ in
                    transitionContext.completeTransition(true)
                }
            }
        })
    }
}
