import MapboxNavigation
import UIKit

extension SceneDelegate: NavigationViewControllerDelegate {
    
    public func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController,
                                                   byCanceling canceled: Bool) {
        let duration = 1.0
        // Hide top and bottom banner containers and after that dismiss `NavigationViewController`.
        navigationViewController.navigationView.topBannerContainerView.hide(duration: duration,
                                                                            animations: {
            navigationViewController.navigationView.topBannerContainerView.alpha = 0.0
        })
        
        navigationViewController.navigationView.bottomBannerContainerView.hide(duration: duration,
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
                
                navigationMapView.delegate = self.previewViewController
                
                // TODO: Implement public method that completely cleans-up `NavigationMapView`.
                navigationMapView.removeRoutes()
                navigationMapView.removeWaypoints()
                navigationMapView.removeArrow()
                navigationMapView.removeRouteDurations()
                navigationMapView.removeContinuousAlternativesRoutes()
                navigationMapView.removeContinuousAlternativeRoutesDurations()
                navigationMapView.userLocationStyle = .puck2D()
                
                // Depending on currently presented banner perform required map or camera modifications.
                if let routesPreviewViewController = self.previewViewController.topBanner(.bottomLeading) as? RoutesPreviewViewController {
                    let routeResponse = routesPreviewViewController.routesPreviewOptions.routeResponse
                    self.previewViewController.showcase(routeResponse: routeResponse)
                    navigationView.bottomBannerContainerView.show(duration: duration,
                                                                  animations: { [weak self] in
                        guard let self = self else { return }
                        self.previewViewController.navigationView.floatingStackView.alpha = 1.0
                    })
                } else if self.previewViewController.topBanner(.bottomLeading) is DestinationPreviewViewController {
                    navigationView.bottomBannerContainerView.show()
                }
            }
        })
    }
}
