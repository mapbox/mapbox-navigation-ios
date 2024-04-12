import MapboxNavigationUIKit
import MapboxNavigationCore
import CoreLocation

// MARK: - DestinationPreviewViewControllerDelegate methods

extension SceneDelegate: DestinationPreviewViewControllerDelegate {
    
    func didTapPreviewRoutesButton(_ destinationPreviewViewController: DestinationPreviewViewController) {
        guard let destinationPreviewViewController = previewViewController.topBanner(at: .bottomLeading) as? DestinationPreviewViewController else {
            return
        }
        
        Task { [weak self] in
            guard let self,
                  let routes = await self.requestRoute(between: destinationPreviewViewController.destinationOptions.coordinates) else {
                return
            }
            
            self.preview(routes, animated: self.shouldAnimate, duration: self.animationDuration)
        }
    }
    
    func didTapBeginActiveNavigationButton(_ destinationPreviewViewController: DestinationPreviewViewController) {
        Task { [weak self] in
            guard let self,
                  let routes = await self.requestRoute(between: destinationPreviewViewController.destinationOptions.coordinates) else {
                return
            }
            
            self.previewViewController.navigationView.navigationMapView.show(routes, routeAnnotationKinds: [.relativeDurationsOnAlternative])
            self.startActiveNavigation(for: routes)
        }
    }
    
    private func requestRoute(between coordinates: [CLLocationCoordinate2D]) async -> NavigationRoutes? {
        do  {
            let navigationRouteOptions = NavigationRouteOptions(coordinates: coordinates)
            return try await navigationProvider.routingProvider().calculateRoutes(options: navigationRouteOptions).value
        } catch {
            print("Error occured while requesting routes: \(error.localizedDescription)")
            return nil
        }
    }
}
