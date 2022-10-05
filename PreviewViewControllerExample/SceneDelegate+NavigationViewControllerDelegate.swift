import MapboxNavigation
import UIKit

extension SceneDelegate: NavigationViewControllerDelegate {
    
    public func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController,
                                                   byCanceling canceled: Bool) {
        // Hide top and bottom banner containers and after that dismiss `NavigationViewController`.
        navigationViewController.navigationView.topBannerContainerView.hide(duration: 3.0,
                                                                            animations: {
            navigationViewController.navigationView.topBannerContainerView.alpha = 0.0
        })
        
        navigationViewController.navigationView.bottomBannerContainerView.hide(duration: 3.0,
                                                                               animations: {
            navigationViewController.navigationView.bottomBannerContainerView.alpha = 0.0
            navigationViewController.navigationView.speedLimitView.alpha = 0.0
            navigationViewController.navigationView.wayNameView.alpha = 0.0
            navigationViewController.navigationView.floatingStackView.alpha = 0.0
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            
            navigationViewController.dismiss(animated: true) {
                let navigationView = self.previewViewController.navigationView
                let navigationMapView = navigationView.navigationMapView
                
                // TODO: Implement public method that completely cleans-up `NavigationMapView`.
                navigationMapView.removeRoutes()
                navigationMapView.removeWaypoints()
                navigationMapView.removeArrow()
                navigationMapView.removeRouteDurations()
                navigationMapView.removeContinuousAlternativesRoutes()
                navigationMapView.removeContinuousAlternativeRoutesDurations()
                navigationMapView.userLocationStyle = .puck2D()
                
                // TODO: Depending on currently presented banner perform required map modifications. For example:
                // - Camera fitting to requested route response
                // - Showing top/bottom banner container views
                if let routesPreviewViewController = self.previewViewController.topmostBottomBanner as? RoutesPreviewViewController {
                    let routeResponse = routesPreviewViewController.routesPreviewOptions.routeResponse
                    self.previewViewController.showcase(routeResponse: routeResponse)
                    navigationView.bottomBannerContainerView.show()
                } else if let _ = self.previewViewController.topmostBottomBanner as? DestinationPreviewViewController {
                    navigationView.bottomBannerContainerView.show()
                }
            }
        })
    }
}
