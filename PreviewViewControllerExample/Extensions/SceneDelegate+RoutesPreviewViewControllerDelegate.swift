import MapboxNavigation

// MARK: - RoutePreviewViewControllerDelegate methods

extension SceneDelegate: RoutePreviewViewControllerDelegate {
    
    func didPressBeginActiveNavigationButton(_ routePreviewViewController: RoutePreviewViewController) {
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
}
