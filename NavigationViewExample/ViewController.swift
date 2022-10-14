import UIKit
import CoreLocation
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import MapboxMaps

class ViewController: UIViewController {
    
    var navigationView: NavigationView!
    
    var navigationRouteOptions: NavigationRouteOptions!
    
    var currentRouteIndex = 0 {
        didSet {
            guard let currentRoute = currentRoute else { return }
            
            var routes = [currentRoute]
            routes.append(contentsOf: self.routes!.filter {
                $0 != currentRoute
            })
            
            navigationView.navigationMapView.showcase(routes,
                                                      routesPresentationStyle: .all(),
                                                      animated: true) { [weak self] _ in
                guard let self = self,
                      let routeResponse = self.routeResponse else {
                    return
                }
                
                let indexedRouteResponse = IndexedRouteResponse(routeResponse: routeResponse,
                                                                routeIndex: self.currentRouteIndex)
                
                let navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                                credentials: NavigationSettings.shared.directions.credentials,
                                                                simulating: .always)
                
                let navigationOptions = NavigationOptions(navigationService: navigationService)
                
                let navigationViewController = NavigationViewController(for: indexedRouteResponse,
                                                                        navigationOptions: navigationOptions)
                
                navigationViewController.modalPresentationStyle = .fullScreen
                navigationViewController.delegate = self
                
                // `ViewController` should assign `transitioningDelegate` to `self` for
                // `PresentationAnimator` and `DismissalAnimator` to work correctly.
                navigationViewController.transitioningDelegate = self
                
                // `NavigationViewController` should be presented with animation for
                // `PresentationAnimator` to work correctly.
                self.present(navigationViewController,
                             animated: true,
                             completion: {
                    // Change user location style to show view that represents user’s location and course on the map.
                    navigationViewController.navigationMapView?.userLocationStyle = .courseView()
                    
                    // Render part of the route that has been traversed with full transparency, to give the illusion of a disappearing route.
                    navigationViewController.routeLineTracksTraversal = true
                    
                    // Hide top and bottom container views before animating their presentation.
                    navigationViewController.navigationView.bottomBannerContainerView.hide(animated: false)
                    navigationViewController.navigationView.topBannerContainerView.hide(animated: false)
                    
                    // Hide `WayNameView`, `FloatingStackView` and `SpeedLimitView` to smoothly present them.
                    navigationViewController.navigationView.wayNameView.alpha = 0.0
                    navigationViewController.navigationView.floatingStackView.alpha = 0.0
                    navigationViewController.navigationView.speedLimitView.alpha = 0.0
                    
                    // Animate top and bottom banner views presentation.
                    navigationViewController.navigationView.bottomBannerContainerView.show(duration: 1.0,
                                                                                           animations: {
                        navigationViewController.navigationView.wayNameView.alpha = 1.0
                        navigationViewController.navigationView.floatingStackView.alpha = 1.0
                        navigationViewController.navigationView.speedLimitView.alpha = 1.0
                    })
                    navigationViewController.navigationView.topBannerContainerView.show(duration: 1.0)
                })
            }
        }
    }
    
    var currentRoute: Route? {
        return routes?[currentRouteIndex]
    }
    
    var routes: [Route]? {
        return routeResponse?.routes
    }
    
    var routeResponse: RouteResponse? {
        didSet {
            guard currentRoute != nil else {
                navigationView.navigationMapView.removeRoutes()
                return
            }
            currentRouteIndex = 0
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationView = NavigationView(frame: view.bounds)
        navigationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationView)
        
        NSLayoutConstraint.activate([
            navigationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationView.topAnchor.constraint(equalTo: view.topAnchor),
            navigationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        navigationView.floatingButtons = nil
        
        let navigationViewportDataSource = NavigationViewportDataSource(navigationView.navigationMapView.mapView,
                                                                        viewportDataSourceType: .raw)
        navigationView.navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
        navigationView.navigationMapView.navigationCamera.follow()
        navigationView.navigationMapView.delegate = self
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self,
                                                                      action: #selector(handleLongPress(_:)))
        navigationView.navigationMapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else { return }
        let location = navigationView.navigationMapView.mapView.mapboxMap.coordinate(for: gesture.location(in: navigationView.navigationMapView.mapView))
        
        requestRoute(destination: location)
    }
    
    func requestRoute(destination: CLLocationCoordinate2D) {
        guard let origin = navigationView.navigationMapView.mapView.location.latestLocation?.coordinate else { return }
        
        let navigationRouteOptions = NavigationRouteOptions(coordinates: [
            origin,
            destination
        ])
        
        Directions.shared.calculate(navigationRouteOptions) { [weak self] (_, result) in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                guard let self = self else { return }
                
                self.navigationRouteOptions = navigationRouteOptions
                self.routeResponse = response
            }
        }
    }
}

extension ViewController: NavigationMapViewDelegate {
    
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        currentRouteIndex = routes?.firstIndex(of: route) ?? 0
    }
}

extension ViewController: UIViewControllerTransitioningDelegate {
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissalAnimator()
    }
    
    public func animationController(forPresented presented: UIViewController,
                                    presenting: UIViewController,
                                    source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentationAnimator()
    }
}

extension ViewController: NavigationViewControllerDelegate {
    
    public func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController,
                                                   byCanceling canceled: Bool) {
        // Hide top and bottom banner containers.
        navigationViewController.navigationView.topBannerContainerView.hide(animated: true,
                                                                            duration: 1.0,
                                                                            animations: {
            navigationViewController.navigationView.topBannerContainerView.alpha = 0.0
        })
        
        navigationViewController.navigationView.bottomBannerContainerView.hide(animated: true,
                                                                               duration: 1.0,
                                                                               animations: {
            navigationViewController.navigationView.bottomBannerContainerView.alpha = 0.0
            navigationViewController.navigationView.wayNameView.alpha = 0.0
            navigationViewController.navigationView.floatingStackView.alpha = 0.0
            navigationViewController.navigationView.speedLimitView.alpha = 0.0
        },
                                                                               completion: { [weak self] _ in
            guard let self = self else { return }
            
            navigationViewController.dismiss(animated: true,
                                             completion: {
                // To receive gesture events delegate should be re-assigned back to `ViewController`.
                self.navigationView.navigationMapView.delegate = self
                
                let navigationViewportDataSource = NavigationViewportDataSource(self.navigationView.navigationMapView.mapView,
                                                                                viewportDataSourceType: .raw)
                self.navigationView.navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
                self.navigationView.navigationMapView.navigationCamera.follow()
                
                // Use default puck style.
                self.navigationView.navigationMapView.userLocationStyle = .puck2D()
                
                // Show routes that were originally requested and remove the ones that were added during
                // active navigation (along with waypoints, continuous alternatives, route durations etc).
                if let routes = self.routes {
                    let cameraOptions = CameraOptions(bearing: 0.0, pitch: 0.0)
                    self.navigationView.navigationMapView.showcase(routes,
                                                                   routesPresentationStyle: .all(shouldFit: true, cameraOptions: cameraOptions),
                                                                   animated: true,
                                                                   duration: 1.0)
                }
            })
        })
    }
}
