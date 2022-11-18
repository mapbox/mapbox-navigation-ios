import UIKit
import CoreLocation
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    var previewViewController: PreviewViewController!
    
    let shouldAnimate = true
    
    let animationDuration = 0.5
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        previewViewController = PreviewViewController()
        previewViewController.delegate = self
        previewViewController.navigationMapView.delegate = self
        
        window?.rootViewController = previewViewController
        window?.makeKeyAndVisible()
        
        setupGestureRecognizers()
    }
    
    // MARK: - Gesture recognizers and presentation methods
    
    func setupGestureRecognizers() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        previewViewController.navigationMapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended,
              let passiveLocationProvider = previewViewController.navigationMapView.mapView.location.locationProvider as? PassiveLocationProvider,
              let originCoordinate = passiveLocationProvider.locationManager.location?.coordinate else { return }
        
        let destinationCoordinate = previewViewController.navigationMapView.mapView.mapboxMap.coordinate(for: gesture.location(in: previewViewController.navigationView.navigationMapView.mapView))
        let coordinates = [
            originCoordinate,
            destinationCoordinate,
        ]
        
        let topmostBottomBanner = previewViewController.topBanner(at: .bottomLeading)
        
        // In case if `RoutePreviewViewController` is shown - don't do anything.
        if topmostBottomBanner is RoutePreviewViewController {
            return
        }
        
        // In case if `DestinationPreviewViewController` is shown - dismiss it and after that show new one.
        if topmostBottomBanner is DestinationPreviewViewController {
            previewViewController.dismissBanner(at: .bottomLeading,
                                                animated: false)
            preview(coordinates,
                    animated: false)
        } else {
            if shouldAnimate {
                previewViewController.navigationView.topBannerContainerView.alpha = 0.0
                previewViewController.navigationView.bottomBannerContainerView.alpha = 0.0
            }
            
            preview(coordinates,
                    animated: shouldAnimate,
                    duration: animationDuration,
                    animations: { [self] in
                self.previewViewController.navigationView.topBannerContainerView.alpha = 1.0
                self.previewViewController.navigationView.bottomBannerContainerView.alpha = 1.0
            })
        }
    }
    
    func presentBannerDismissalViewControllerIfNeeded(_ animated: Bool,
                                                      duration: TimeInterval) {
        if previewViewController.topBanner(at: .topLeading) is BannerDismissalViewController {
            return
        }
        
        let bannerDismissalViewController = BannerDismissalViewController()
        bannerDismissalViewController.delegate = self
        previewViewController.present(bannerDismissalViewController,
                                      animated: animated,
                                      duration: duration)
    }
    
    func preview(_ coordinates: [CLLocationCoordinate2D],
                 animated: Bool = true,
                 duration: TimeInterval = 1.0,
                 animations: (() -> Void)? = nil,
                 completion: (() -> Void)? = nil) {
        if coordinates.isEmpty {
            preconditionFailure("Waypoints array should not be empty.")
        }
        
        let destinationOptions = DestinationOptions(coordinates: coordinates)
        let destinationPreviewViewController = DestinationPreviewViewController(destinationOptions)
        destinationPreviewViewController.delegate = self
        previewViewController.present(destinationPreviewViewController,
                                      animated: animated,
                                      duration: duration,
                                      animations: animations,
                                      completion: {
            completion?()
        })
        
        presentBannerDismissalViewControllerIfNeeded(animated,
                                                     duration: duration)
        
        // TODO: Implement the ability to add final destination annotations.
    }
    
    func preview(_ routeResponse: RouteResponse,
                 routeIndex: Int = 0,
                 animated: Bool = true,
                 duration: TimeInterval = 1.0,
                 animations: (() -> Void)? = nil,
                 completion: (() -> Void)? = nil) {
        let routePreviewOptions = RoutePreviewOptions(routeResponse: routeResponse, routeIndex: routeIndex)
        let routePreviewViewController = RoutePreviewViewController(routePreviewOptions)
        routePreviewViewController.delegate = self
        previewViewController.present(routePreviewViewController,
                                      animated: animated,
                                      duration: duration,
                                      animations: animations)
        
        presentBannerDismissalViewControllerIfNeeded(animated,
                                                     duration: duration)
        
        showcase(routeResponse: routeResponse,
                 routeIndex: routeIndex,
                 animated: animated,
                 duration: duration,
                 completion: { _ in
            completion?()
        })
    }
    
    func showcase(routeResponse: RouteResponse,
                  routeIndex: Int = 0,
                  animated: Bool = true,
                  duration: TimeInterval = 1.0,
                  completion: NavigationMapView.AnimationCompletionHandler? = nil) {
        guard var routes = routeResponse.routes else { return }
        
        routes.insert(routes.remove(at: routeIndex), at: 0)
        
        let cameraOptions = previewViewController.navigationView.previewCameraOptions()
        let routesPresentationStyle: RoutesPresentationStyle = .all(shouldFit: true,
                                                                    cameraOptions: cameraOptions)
        
        previewViewController.navigationMapView.showcase(routes,
                                                         routesPresentationStyle: routesPresentationStyle,
                                                         animated: animated,
                                                         duration: duration,
                                                         completion: completion)
    }
}
