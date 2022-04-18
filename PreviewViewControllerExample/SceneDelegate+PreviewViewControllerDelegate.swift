import UIKit
import CoreLocation
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections
import MapboxGeocoder

extension SceneDelegate: PreviewViewControllerDelegate {
    
    func previewViewControllerWillPreviewRoutes(_ previewViewController: PreviewViewController) {
        let navigationRouteOptions = NavigationRouteOptions(coordinates: coordinates)
        
        Directions.shared.calculate(navigationRouteOptions) { [weak self] (_, result) in
            switch result {
            case .failure(let error):
                NSLog("Error occured: \(error.localizedDescription).")
            case .success(let routeResponse):
                guard let self = self else { return }
                
                self.routeResponse = routeResponse
                
                previewViewController.preview(routeResponse)
            }
        }
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               bottomBannerViewControllerFor state: PreviewViewController.State) -> UIViewController? {
        switch state {
        case .browsing:
            if useCustomBannerViews {
                let customViewController = UIViewController()
                customViewController.view.backgroundColor = .green
                
                return customViewController
            }
            
            return nil
        case .destinationPreviewing(let destinationOptions):
            if useCustomBannerViews {
                let customDestinationPreviewViewController = CustomDestinationPreviewViewController(destinationOptions)
                customDestinationPreviewViewController.delegate = self
                
                return customDestinationPreviewViewController
            }
            
            return nil
        case .routesPreviewing(let routesPreviewOptions):
            if useCustomBannerViews {
                let customRoutesPreviewViewController = CustomRoutesPreviewViewController(routesPreviewOptions)
                customRoutesPreviewViewController.delegate = self
                
                return customRoutesPreviewViewController
            }
            
            return nil
        }
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               stateDidChangeTo state: PreviewViewController.State) {
        switch state {
        case .browsing:
            routeResponse = nil
            routeIndex = 0
            coordinates = []
            break
        case .destinationPreviewing:
            break
        case .routesPreviewing:
            break
        }
    }
    
    func previewViewControllerWillBeginNavigation(_ previewViewController: PreviewViewController) {
        startActiveNavigation(for: routeResponse)
    }
    
    func previewViewController(_ previewViewController: PreviewViewController,
                               didLongPressFor coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates
        
        guard let destinationCoordinate = coordinates.last else {
            return
        }
        
        let finalWaypoint = Waypoint(coordinate: destinationCoordinate,
                                     coordinateAccuracy: nil,
                                     name: "Final destination")
        
        previewViewController.preview([finalWaypoint])
        
        let locationManager = CLLocationManager()
        let reverseGeocodeOptions = ReverseGeocodeOptions(coordinate: destinationCoordinate)
        reverseGeocodeOptions.focalLocation = locationManager.location
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

            (previewViewController.presentedBottomBannerViewController as? DestinationPreviewViewController)?.destinationOptions.primaryText = placemark.formattedName
        })
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
        
        let navigationRouteOptions = NavigationRouteOptions(coordinates: coordinates)
        let navigationService = MapboxNavigationService(routeResponse: routeResponse,
                                                        routeIndex: routeIndex,
                                                        routeOptions: navigationRouteOptions,
                                                        routingProvider: NavigationSettings.shared.directions,
                                                        credentials: NavigationSettings.shared.directions.credentials,
                                                        simulating: .always)
        
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: routeResponse,
                                                                   routeIndex: routeIndex,
                                                                   routeOptions: navigationRouteOptions,
                                                                   navigationOptions: navigationOptions)
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen
        window?.rootViewController?.present(navigationViewController, animated: false, completion: nil)
    }
}
