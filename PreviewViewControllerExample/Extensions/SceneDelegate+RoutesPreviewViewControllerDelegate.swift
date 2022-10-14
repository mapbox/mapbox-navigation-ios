import MapboxNavigation

// MARK: - RoutesPreviewViewControllerDelegate methods

extension SceneDelegate: RoutesPreviewViewControllerDelegate {
    
    func didPressBeginActiveNavigationButton(_ routesPreviewViewController: RoutesPreviewViewController) {
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
}
