import UIKit
import CoreLocation
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections
import MapboxGeocoder

extension SceneDelegate: PreviewViewControllerDelegate {
    
    // MARK: - PreviewViewControllerDelegate methods
    
    func didPressPreviewRoutesButton(_ previewViewController: PreviewViewController) {
        guard let destinationPreviewViewController = previewViewController.topBanner(at: .bottomLeading) as? DestinationPreviewViewController else {
            return
        }
        
        requestRoute(between: destinationPreviewViewController.destinationOptions.coordinates,
                     completion: { [weak self] routeResponse in
            guard let self = self else { return }
            previewViewController.preview(routeResponse,
                                          animated: self.shouldAnimate,
                                          duration: self.animationDuration)
        })
    }
    
    func didPressDismissBannerButton(_ previewViewController: PreviewViewController) {
        previewViewController.dismissBanner(at: .bottomLeading,
                                            animated: shouldAnimate,
                                            duration: animationDuration)
        
        // In case if there are no more bottom banners - dismiss top banner as well.
        if previewViewController.topBanner(at: .bottomLeading) == nil {
            previewViewController.dismissBanner(at: .topLeading,
                                                animated: shouldAnimate,
                                                duration: animationDuration,
                                                animations: {
                previewViewController.navigationView.topBannerContainerView.alpha = 0.0
            }, completion: {
                previewViewController.navigationView.topBannerContainerView.alpha = 1.0
            })
        }
    }
    
    func didPressBeginActiveNavigationButton(_ previewViewController: PreviewViewController) {
        if let previewViewController = previewViewController.topBanner(at: .bottomLeading) as? RoutesPreviewViewController {
            let routeResponse = previewViewController.routesPreviewOptions.routeResponse
            startActiveNavigation(for: routeResponse)
        } else {
            if let destinationPreviewViewController = previewViewController.topBanner(at: .bottomLeading) as? DestinationPreviewViewController {
                let coordinates = destinationPreviewViewController.destinationOptions.coordinates
                requestRoute(between: coordinates) { [weak self] routeResponse in
                    guard let self = self,
                          let routes = routeResponse.routes else {
                        return
                    }
                    
                    self.previewViewController.navigationView.navigationMapView.show(routes)
                    self.startActiveNavigation(for: routeResponse)
                }
            }
        }
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didAddDestinationBetween coordinates: [CLLocationCoordinate2D]) {
        let topmostBottomBanner = previewViewController.topBanner(at: .bottomLeading)
        
        // In case if `RoutesPreviewViewController` is shown - don't do anything.
        if topmostBottomBanner is RoutesPreviewViewController {
            return
        }
        
        // In case if `DestinationPreviewViewController` is shown - dismiss it and after that show new one.
        if topmostBottomBanner is DestinationPreviewViewController {
            previewViewController.dismissBanner(at: .bottomLeading,
                                                animated: false)
            previewViewController.preview(coordinates,
                                          animated: false)
        } else {
            if shouldAnimate {
                previewViewController.navigationView.topBannerContainerView.alpha = 0.0
                previewViewController.navigationView.bottomBannerContainerView.alpha = 0.0
            }
            
            previewViewController.preview(coordinates,
                                          animated: shouldAnimate,
                                          duration: animationDuration,
                                          animations: {
                previewViewController.navigationView.topBannerContainerView.alpha = 1.0
                previewViewController.navigationView.bottomBannerContainerView.alpha = 1.0
            })
        }
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didSelect route: Route) {
        let topmostBottomBanner = previewViewController.topBanner(at: .bottomLeading)
        
        guard let routesPreviewViewController = topmostBottomBanner as? RoutesPreviewViewController,
              let routes = routesPreviewViewController.routesPreviewOptions.routeResponse.routes,
              let routeIndex = routes.firstIndex(where: { $0 === route }) else {
            return
        }
        
        previewViewController.dismissBanner(at: .bottomLeading,
                                            animated: false)
        
        previewViewController.preview(routesPreviewViewController.routesPreviewOptions.routeResponse,
                                      routeIndex: routeIndex,
                                      animated: false)
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willPresent banner: Banner) {
        guard let destinationPreviewViewController = banner as? DestinationPreviewViewController,
              let destinationCoordinate = destinationPreviewViewController.destinationOptions.coordinates.last else {
            return
        }
        
        reverseGeocode(destinationCoordinate) { placemarkName in
            destinationPreviewViewController.destinationOptions.primaryText = NSAttributedString(string: placemarkName)
        }
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didPresent banner: Banner) {
        // No-op
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willDismiss banner: Banner) {
        // No-op
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didDismiss banner: Banner) {
        // No-op
    }
    
    // MARK: - Helper methods
    
    func startActiveNavigation(for routeResponse: RouteResponse,
                               routeIndex: Int = 0) {
        previewViewController.navigationView.topBannerContainerView.hide(animated: shouldAnimate,
                                                                         duration: animationDuration,
                                                                         animations: {
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
            
            self.previewViewController.present(navigationViewController,
                                               animated: true,
                                               completion: { [weak self] in
                guard let self = self else { return }
                // Make `SceneDelegate` delegate of `NavigationViewController` to be notified about
                // its dismissal.
                navigationViewController.delegate = self
                
                // Switch navigation camera to active navigation mode.
                navigationViewController.navigationMapView?.navigationCamera.viewportDataSource = NavigationViewportDataSource(navigationViewController.navigationView.navigationMapView.mapView,
                                                                                                                               viewportDataSourceType: .active)
                navigationViewController.navigationMapView?.navigationCamera.follow()
                
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
    
    func requestRoute(between coordinates: [CLLocationCoordinate2D],
                      completion: @escaping (_ routeResponse: RouteResponse) -> Void) {
        let navigationRouteOptions = NavigationRouteOptions(coordinates: coordinates)
        
        Directions.shared.calculate(navigationRouteOptions) { (_, result) in
            switch result {
            case .failure(let error):
                print("Error occured while requesting routes: \(error.localizedDescription)")
            case .success(let routeResponse):
                completion(routeResponse)
            }
        }
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
