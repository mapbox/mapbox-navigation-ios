import UIKit
import CoreLocation
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections
import MapboxGeocoder

extension SceneDelegate: PreviewViewControllerDelegate {
    
    func requestRoutes(_ completion: @escaping (_ routeResponse: RouteResponse) -> Void) {
        let navigationRouteOptions = NavigationRouteOptions(coordinates: coordinates)
        
        Directions.shared.calculate(navigationRouteOptions) { [weak self] (_, result) in
            switch result {
            case .failure(let error):
                print("Error occured while requesting routes: \(error.localizedDescription)")
            case .success(let routeResponse):
                guard let self = self else { return }
                
                self.routeResponse = routeResponse
                
                completion(routeResponse)
            }
        }
    }
    
    func willPreviewRoutes(_ previewViewController: PreviewViewController) {
        requestRoutes { routeResponse in
            previewViewController.preview(routeResponse)
        }
    }
    
    func willBeginActiveNavigation(_ previewViewController: PreviewViewController) {
        if let routeResponse = routeResponse {
            startActiveNavigation(for: routeResponse)
        } else {
            requestRoutes { [weak self] routeResponse in
                guard let self = self else { return }
                self.startActiveNavigation(for: routeResponse)
            }
        }
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didAddDestinationBetween coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates
        
        guard let destinationCoordinate = coordinates.last else {
            return
        }
        
        let finalWaypoint = Waypoint(coordinate: destinationCoordinate,
                                     coordinateAccuracy: nil,
                                     name: "Final destination")
        
        previewViewController.preview(finalWaypoint)
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didSelect route: Route) {
        guard let routeResponse = routeResponse,
              let routes = routeResponse.routes,
              let routeIndex = routes.firstIndex(where: { $0 === route }) else {
            return
        }
        
        self.routeIndex = routeIndex
        
        previewViewController.preview(routeResponse, routeIndex: routeIndex)
    }
    
    func startActiveNavigation(for routeResponse: RouteResponse?) {
        guard let routeResponse = routeResponse else {
            return
        }
        
        self.previewViewController.navigationView.bottomBannerContainerView.hide(completion: { _ in
            let indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse,
                                                            routeIndex: self.routeIndex)
            let navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                            customRoutingProvider: NavigationSettings.shared.directions,
                                                            credentials: NavigationSettings.shared.directions.credentials,
                                                            simulating: .always)
            
            let navigationOptions = NavigationOptions(navigationService: navigationService)
            let navigationViewController = NavigationViewController(for: indexedRouteResponse,
                                                                       navigationOptions: navigationOptions)
            navigationViewController.modalPresentationStyle = .fullScreen
            navigationViewController.transitioningDelegate = self
            
            self.previewViewController.present(navigationViewController, animated: true, completion: {
                navigationViewController.delegate = self
                
                // Switch navigation camera to active navigation mode.
                navigationViewController.navigationMapView?.navigationCamera.viewportDataSource = NavigationViewportDataSource(navigationViewController.navigationView.navigationMapView.mapView,
                                                                                                                               viewportDataSourceType: .active)
                navigationViewController.navigationMapView?.navigationCamera.follow()
                
                navigationViewController.navigationMapView?.userLocationStyle = .courseView()
                
                // Render part of the route that has been traversed with full transparency, to give the illusion of a disappearing route.
                navigationViewController.routeLineTracksTraversal = true
                
                // Hide top and bottom container views before animating their presentation.
                navigationViewController.navigationView.topBannerContainerView.isHidden = true
                navigationViewController.navigationView.bottomBannerContainerView.isHidden = true
                
                navigationViewController.navigationView.topBannerContainerView.show()
                navigationViewController.navigationView.bottomBannerContainerView.show()
            })
        })
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               willPresent destinationText: NSAttributedString,
                               in destinationPreviewViewController: DestinationPreviewViewController) -> NSAttributedString? {
        let destinationOptions = destinationPreviewViewController.destinationOptions
        let destinationCoordinate = destinationOptions.waypoint.coordinate
        let reverseGeocodeOptions = ReverseGeocodeOptions(coordinate: destinationCoordinate)
        reverseGeocodeOptions.focalLocation = CLLocationManager().location
        reverseGeocodeOptions.locale = Locale.autoupdatingCurrent.languageCode == "en" ? nil : .autoupdatingCurrent
        let allowedScopes: PlacemarkScope = .all
        reverseGeocodeOptions.allowedScopes = allowedScopes
        reverseGeocodeOptions.maximumResultCount = 1
        reverseGeocodeOptions.includesRoutableLocations = true
        
        Geocoder.shared.geocode(reverseGeocodeOptions, completionHandler: { (placemarks, _, error) in
            if let error = error {
                NSLog("Reverse geocoding failed with error: \(error.localizedDescription).")
                return
            }
            
            guard let placemark = placemarks?.first else {
                return
            }
            
            destinationPreviewViewController.destinationOptions.primaryText = placemark.formattedName
        })
        
        return NSAttributedString(string: "")
    }
    
    func bannerWillAppear(_ previewViewController: PreviewViewController, banner: BannerPreviewing) {
        // No-op
    }
    
    func bannerDidAppear(_ previewViewController: PreviewViewController, banner: BannerPreviewing) {
        // No-op
    }
    
    func bannerWillDisappear(_ previewViewController: PreviewViewController, banner: BannerPreviewing) {
        // No-op
    }
    
    func bannerDidDisappear(_ previewViewController: PreviewViewController, banner: BannerPreviewing) {
        // No-op
    }
}