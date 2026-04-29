import CoreLocation
import MapboxDirections
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    var previewViewController: PreviewViewController!
    var initialRoutes: NavigationRoutes?

    let shouldAnimate = true

    let animationDuration = 0.5
    let navigationProvider = MapboxNavigationProvider(coreConfig: CoreConfig())

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)

        previewViewController = PreviewViewController(
            PreviewOptions(
                locationMatching: navigationProvider.navigation().locationMatching,
                routeProgress: navigationProvider.navigation().routeProgress
                    .map(\.?.routeProgress)
                    .eraseToAnyPublisher(),
                predictiveCacheManager: navigationProvider.predictiveCacheManager
            )
        )
        navigationProvider.tripSession().startFreeDrive()
        previewViewController.delegate = self
        previewViewController.navigationMapView.delegate = self

        window?.rootViewController = previewViewController
        window?.makeKeyAndVisible()
    }

    // MARK: - Gesture recognizers and presentation methods

    func presentBannerDismissalViewControllerIfNeeded(
        _ animated: Bool,
        duration: TimeInterval
    ) {
        if previewViewController.topBanner(at: .topLeading) is BannerDismissalViewController {
            return
        }

        let bannerDismissalViewController = BannerDismissalViewController()
        bannerDismissalViewController.delegate = self
        previewViewController.present(
            bannerDismissalViewController,
            animated: animated,
            duration: duration
        )
    }

    func preview(
        _ coordinates: [CLLocationCoordinate2D],
        animated: Bool = true,
        duration: TimeInterval = 1.0,
        animations: (() -> Void)? = nil,
        completion: (() -> Void)? = nil
    ) {
        if coordinates.isEmpty {
            preconditionFailure("Waypoints array should not be empty.")
        }

        let destinationOptions = DestinationOptions(coordinates: coordinates)
        let destinationPreviewViewController = DestinationPreviewViewController(destinationOptions)
        destinationPreviewViewController.delegate = self
        previewViewController.present(
            destinationPreviewViewController,
            animated: animated,
            duration: duration,
            animations: animations,
            completion: {
                completion?()
            }
        )

        presentBannerDismissalViewControllerIfNeeded(
            animated,
            duration: duration
        )

        // TODO: Implement the ability to add final destination annotations.
    }

    func preview(
        _ navigationRoutes: NavigationRoutes,
        animated: Bool = true,
        duration: TimeInterval = 1.0,
        animations: (() -> Void)? = nil
    ) {
        let routePreviewOptions = RoutePreviewOptions(
            navigationRoutes: navigationRoutes,
            routeId: navigationRoutes.mainRoute.routeId
        )
        let routePreviewViewController = RoutePreviewViewController(routePreviewOptions)
        routePreviewViewController.delegate = self
        previewViewController.present(
            routePreviewViewController,
            animated: animated,
            duration: duration,
            animations: animations
        )

        presentBannerDismissalViewControllerIfNeeded(
            animated,
            duration: duration
        )

        showcase(
            navigationRoutes: navigationRoutes,
            animated: animated,
            duration: duration
        )
    }

    func showcase(
        navigationRoutes: NavigationRoutes,
        animated: Bool = true,
        duration: TimeInterval = 1.0
    ) {
        initialRoutes = navigationRoutes
        previewViewController.navigationView.configureViewportPadding()
        previewViewController.navigationMapView.showcase(
            navigationRoutes,
            routesPresentationStyle: .all(shouldFit: true),
            routeAnnotationKinds: [.routeDurations],
            animated: animated,
            duration: duration
        )
    }
}
