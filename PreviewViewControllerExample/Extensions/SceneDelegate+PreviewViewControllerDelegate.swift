import UIKit
import CoreLocation
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections
import MapboxGeocoder

// MARK: - NavigationMapViewDelegate methods

extension SceneDelegate: NavigationMapViewDelegate {
    
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect route: Route) {
        guard let routePreviewViewController = previewViewController.topBanner(at: .bottomLeading) as? RoutePreviewViewController,
              let routes = routePreviewViewController.routePreviewOptions.routeResponse.routes,
              let routeIndex = routes.firstIndex(where: { $0 === route }) else {
            return
        }
        
        previewViewController.dismissBanner(at: .bottomLeading,
                                            animated: false)
        
        preview(routePreviewViewController.routePreviewOptions.routeResponse,
                routeIndex: routeIndex,
                animated: false)
    }
}

// MARK: - PreviewViewControllerDelegate methods

extension SceneDelegate: PreviewViewControllerDelegate {
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willPresent banner: Banner) {
        guard let destinationPreviewViewController = banner as? DestinationPreviewViewController,
              let destinationCoordinate = destinationPreviewViewController.destinationOptions.coordinates.last else {
            return
        }
        
        // While presenting `DestinationPreviewViewController` - override its initial primary text
        // to reverse-geocoded name.
        reverseGeocode(destinationCoordinate) { placemarkName in
            destinationPreviewViewController.destinationOptions.primaryText = NSAttributedString(string: placemarkName)
        }
        
        previewViewController.navigationView.wayNameView.isHidden = true
        previewViewController.navigationView.speedLimitView.isAlwaysHidden = true
        previewViewController.navigationView.navigationMapView.navigationCamera.stop()
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didPresent banner: Banner) {
        // No-op
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willDismiss banner: Banner) {
        if banner is DestinationPreviewViewController {
            // TODO: Implement the ability to remove final destination annotations.
            previewViewController.navigationMapView.removeRoutes()
        } else if banner is RoutePreviewViewController {
            previewViewController.navigationMapView.removeWaypoints()
            previewViewController.navigationMapView.removeRoutes()
        }
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didDismiss banner: Banner) {
        if previewViewController.topBanner(at: .bottomLeading) == nil {
            previewViewController.navigationView.wayNameView.isHidden = false
            previewViewController.navigationView.speedLimitView.isAlwaysHidden = false
        }
    }
    
    // MARK: - Helper methods
    
    func startActiveNavigation(for routeResponse: RouteResponse,
                               routeIndex: Int = 0) {
        previewViewController.navigationView.topBannerContainerView.hide(animated: shouldAnimate,
                                                                         duration: animationDuration,
                                                                         animations: { [weak self] in
            guard let self = self else { return }
            
            self.previewViewController.navigationView.topBannerContainerView.alpha = 0.0
        })
        
        previewViewController.navigationView.bottomBannerContainerView.hide(animated: shouldAnimate,
                                                                            duration: animationDuration,
                                                                            animations: { [weak self] in
            guard let self = self else { return }
            
            self.previewViewController.navigationView.floatingStackView.alpha = 0.0
            self.previewViewController.navigationView.bottomBannerContainerView.alpha = 0.0
        }, completion: { [weak self] _ in
            guard let self = self else { return }
            
            let indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse,
                                                            routeIndex: routeIndex)
            
            let navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                            credentials: NavigationSettings.shared.directions.credentials,
                                                            simulating: .always)
            
            let navigationOptions = NavigationOptions(navigationService: navigationService)
            
            let navigationViewController = NavigationViewController(for: indexedRouteResponse,
                                                                    navigationOptions: navigationOptions)
            navigationViewController.modalPresentationStyle = .fullScreen
            navigationViewController.transitioningDelegate = self
            // Make `SceneDelegate` delegate of `NavigationViewController` to be notified about
            // its dismissal.
            navigationViewController.delegate = self
            
            self.previewViewController.present(navigationViewController,
                                               animated: true,
                                               completion: { [weak self] in
                guard let self = self else { return }
                
                // Change user location style to the one that is used during active navigation.
                navigationViewController.navigationMapView?.userLocationStyle = .courseView()
                
                // Render part of the route that has been traversed with full transparency, to give the illusion of a disappearing route.
                navigationViewController.routeLineTracksTraversal = true
                
                // Hide top and bottom container views before animating their presentation.
                navigationViewController.navigationView.topBannerContainerView.hide(animated: false)
                navigationViewController.navigationView.bottomBannerContainerView.hide(animated: false)
                
                if self.shouldAnimate {
                    navigationViewController.navigationView.speedLimitView.alpha = 0.0
                    navigationViewController.navigationView.wayNameView.alpha = 0.0
                    navigationViewController.navigationView.floatingStackView.alpha = 0.0
                    navigationViewController.navigationView.topBannerContainerView.alpha = 0.0
                    navigationViewController.navigationView.bottomBannerContainerView.alpha = 0.0
                }
                
                navigationViewController.navigationView.topBannerContainerView.show(animated: self.shouldAnimate,
                                                                                    duration: self.animationDuration,
                                                                                    animations: {
                    navigationViewController.navigationView.speedLimitView.alpha = 1.0
                    navigationViewController.navigationView.wayNameView.alpha = 1.0
                    navigationViewController.navigationView.floatingStackView.alpha = 1.0
                    navigationViewController.navigationView.topBannerContainerView.alpha = 1.0
                })
                
                navigationViewController.navigationView.bottomBannerContainerView.show(animated: self.shouldAnimate,
                                                                                       duration: self.animationDuration,
                                                                                       animations: {
                    navigationViewController.navigationView.bottomBannerContainerView.alpha = 1.0
                })
            })
        })
    }
    
    func reverseGeocode(_ coordinate: CLLocationCoordinate2D,
                        completion: @escaping (_ placemarkName: String) -> Void) {
        let reverseGeocodeOptions = ReverseGeocodeOptions(coordinate: coordinate)
        reverseGeocodeOptions.focalLocation = CLLocationManager().location
        reverseGeocodeOptions.locale = Locale.autoupdatingCurrent.languageCode == "en" ? nil : .autoupdatingCurrent
        reverseGeocodeOptions.allowedScopes = .all
        reverseGeocodeOptions.maximumResultCount = 1
        reverseGeocodeOptions.includesRoutableLocations = true
        
        Geocoder.shared.geocode(reverseGeocodeOptions, completionHandler: { (placemarks, _, error) in
            if let error = error {
                print("Reverse geocoding failed with error: \(error.localizedDescription)")
                return
            }
            
            guard let placemark = placemarks?.first else {
                print("Placemark was not found")
                return
            }
            
            completion(placemark.formattedName)
        })
    }
}
