import UIKit
import CoreLocation
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections

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
    
    func destinationPreviewViewController(for previewViewController: PreviewViewController) -> DestinationableViewController? {
        if useCustomBannerViews {
            let destinationOptions = DestinationOptions(coordinates: coordinates)
            let customDestinationPreviewViewController = CustomDestinationPreviewViewController(destinationOptions)
            customDestinationPreviewViewController.delegate = self
            
            return customDestinationPreviewViewController
        }
        
        return nil
    }
    
    func routesPreviewViewController(for previewViewController: PreviewViewController) -> PreviewableViewController? {
        if useCustomBannerViews {
            guard let routeResponse = routeResponse else {
                return nil
            }
            
            let previewOptions = PreviewOptions(routeResponse: routeResponse, routeIndex: routeIndex)
            let customRoutesPreviewViewController = CustomRoutesPreviewViewController(previewOptions)
            customRoutesPreviewViewController.delegate = self
            
            return customRoutesPreviewViewController
        }
        
        return nil
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
        if let destination = coordinates.last {
            previewViewController.preview([destination])
        }
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
