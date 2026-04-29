import MapboxNavigationUIKit

// MARK: - RoutePreviewViewControllerDelegate methods

extension SceneDelegate: RoutePreviewViewControllerDelegate {
    func didPressBeginActiveNavigationButton(_ routePreviewViewController: RoutePreviewViewController) {
        startActiveNavigation(for: routePreviewViewController.routePreviewOptions.navigationRoutes)
    }
}
