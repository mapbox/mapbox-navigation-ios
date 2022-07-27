import UIKit
import CoreLocation
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

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
                                                      animated: true) { _ in
                guard let routeResponse = self.routeResponse else { return }
                
                let navigationService = MapboxNavigationService(routeResponse: routeResponse,
                                                                routeIndex: self.currentRouteIndex,
                                                                routeOptions: self.navigationRouteOptions,
                                                                customRoutingProvider: NavigationSettings.shared.directions,
                                                                credentials: NavigationSettings.shared.directions.credentials,
                                                                simulating: .always)
                
                let navigationOptions = NavigationOptions(navigationService: navigationService)
                let navigationViewController = NavigationViewController(for: routeResponse,
                                                                        routeIndex: self.currentRouteIndex,
                                                                        routeOptions: self.navigationRouteOptions,
                                                                        navigationOptions: navigationOptions)
                navigationViewController.modalPresentationStyle = .fullScreen
                navigationViewController.delegate = self
                
                // `ViewController` should assign `transitioningDelegate` to `self` for
                // `PresentationAnimator` and `DismissalAnimator` to work correctly.
                navigationViewController.transitioningDelegate = self
                
                // `NavigationViewController` should be presented with animation for
                // `PresentationAnimator` to work correctly.
                self.present(navigationViewController, animated: true)
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
        // `NavigationViewController` should be dismissed with animation for
        // `DismissalAnimator` to work correctly.
        navigationViewController.dismiss(animated: true)
    }
}
