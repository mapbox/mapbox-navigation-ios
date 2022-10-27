import MapboxNavigation
import UIKit

extension SceneDelegate: NavigationViewControllerDelegate {
    
    public func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController,
                                                   byCanceling canceled: Bool) {
        // Hide top and bottom banner containers and after that dismiss `NavigationViewController`.
        navigationViewController.navigationView.topBannerContainerView.hide(animated: shouldAnimate,
                                                                            duration: animationDuration,
                                                                            animations: {
            navigationViewController.navigationView.topBannerContainerView.alpha = 0.0
        })
        
        navigationViewController.navigationView.bottomBannerContainerView.hide(animated: shouldAnimate,
                                                                               duration: animationDuration,
                                                                               animations: {
            navigationViewController.navigationView.bottomBannerContainerView.alpha = 0.0
            navigationViewController.navigationView.speedLimitView.alpha = 0.0
            navigationViewController.navigationView.wayNameView.alpha = 0.0
            navigationViewController.navigationView.floatingStackView.alpha = 0.0
        },
                                                                               completion: { _ in
            navigationViewController.dismiss(animated: true) { [weak self] in
                guard let self = self else { return }
                
                let navigationView = self.previewViewController.navigationView
                let navigationMapView = navigationView.navigationMapView
                
                navigationMapView.delegate = self
                
                // TODO: Implement public method that completely cleans-up `NavigationMapView`.
                navigationMapView.removeRoutes()
                navigationMapView.removeWaypoints()
                navigationMapView.removeArrow()
                navigationMapView.removeRouteDurations()
                navigationMapView.removeContinuousAlternativesRoutes()
                navigationMapView.removeContinuousAlternativeRoutesDurations()
                navigationMapView.userLocationStyle = .puck2D()
                
                self.showcase(routeResponse: navigationViewController.routeResponse,
                              animated: self.shouldAnimate,
                              duration: self.animationDuration)
                
                navigationView.topBannerContainerView.show(animated: self.shouldAnimate,
                                                           duration: self.animationDuration,
                                                           animations: {
                    navigationView.topBannerContainerView.alpha = 1.0
                })
                
                navigationView.bottomBannerContainerView.show(animated: self.shouldAnimate,
                                                              duration: self.animationDuration,
                                                              animations: {
                    navigationView.floatingStackView.alpha = 1.0
                    navigationView.bottomBannerContainerView.alpha = 1.0
                })
            }
        })
    }
}
