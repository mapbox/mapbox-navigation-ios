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
            
            // `NavigationMapView` should be transfered back from `NavigationViewController` to `ViewController`.
            toViewController.navigationView.navigationMapView = fromViewController.navigationView.navigationMapView
            
            // To receive gesture events delegate should be re-assigned back to `ViewController`.
            toViewController.navigationView.navigationMapView.delegate = toViewController
            
            // Use default puck style.
            toViewController.navigationView.navigationMapView.userLocationStyle = .puck2D()
            
            // Show routes that were originally requested and remove the ones that were added during
            // active navigation (along with waypoints, continuous alternatives, route durations etc).
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
