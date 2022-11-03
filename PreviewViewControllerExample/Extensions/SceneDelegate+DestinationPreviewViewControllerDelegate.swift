import MapboxNavigation
import MapboxDirections
import MapboxCoreNavigation
import CoreLocation

// MARK: - DestinationPreviewViewControllerDelegate methods

extension SceneDelegate: DestinationPreviewViewControllerDelegate {
    
    func didTapPreviewRoutesButton(_ destinationPreviewViewController: MapboxNavigation.DestinationPreviewViewController) {
        guard let destinationPreviewViewController = previewViewController.topBanner(at: .bottomLeading) as? DestinationPreviewViewController else {
            return
        }
        
        requestRoute(between: destinationPreviewViewController.destinationOptions.coordinates,
                     completion: { [weak self] routeResponse in
            guard let self = self else { return }
            self.preview(routeResponse,
                         animated: self.shouldAnimate,
                         duration: self.animationDuration)
        })
    }
    
    func didTapBeginActiveNavigationButton(_ destinationPreviewViewController: MapboxNavigation.DestinationPreviewViewController) {
        if let routePreviewViewController = previewViewController.topBanner(at: .bottomLeading) as? RoutePreviewViewController {
            let routeResponse = routePreviewViewController.routePreviewOptions.routeResponse
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
}
