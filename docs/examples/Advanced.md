
_Source available [here](https://github.com/mapbox/navigation-ios-examples/blob/master/Navigation-Examples/Examples/Advanced.swift)_

```swift
import UIKit
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections
import Mapbox


class AdvancedViewController: UIViewController, MGLMapViewDelegate, CLLocationManagerDelegate, NavigationMapViewDelegate, NavigationViewControllerDelegate {
    
    var mapView: NavigationMapView?
    var currentRoute: Route? {
        get {
            return routes?.first
        }
        set {
            guard let selected = newValue else { routes?.remove(at: 0); return }
            guard let routes = routes else { self.routes = [selected]; return }
            self.routes = [selected] + routes.filter { $0 != selected }
        }
    }
    var routes: [Route]? {
        didSet {
            guard let routes = routes, let current = routes.first else { mapView?.removeRoutes(); return }
            mapView?.showRoutes(routes)
            mapView?.showWaypoints(current)
        }
    }
    var startButton: UIButton?
    var locationManager = CLLocationManager()
    
    private typealias RouteRequestSuccess = (([Route]) -> Void)
    private typealias RouteRequestFailure = ((NSError) -> Void)
    
    //MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        mapView = NavigationMapView(frame: view.bounds)
        mapView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView?.userTrackingMode = .follow
        mapView?.delegate = self
        mapView?.navigationMapDelegate = self
        
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        mapView?.addGestureRecognizer(gesture)
        
        view.addSubview(mapView!)
        
        startButton = UIButton()
        startButton?.setTitle("Start Navigation", for: .normal)
        startButton?.translatesAutoresizingMaskIntoConstraints = false
        startButton?.backgroundColor = .blue
        startButton?.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startButton?.addTarget(self, action: #selector(tappedButton(sender:)), for: .touchUpInside)
        startButton?.isHidden = true
        view.addSubview(startButton!)
        startButton?.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        startButton?.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        view.setNeedsLayout()
    }
    
    //overriding layout lifecycle callback so we can style the start button
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        startButton?.layer.cornerRadius = startButton!.bounds.midY
        startButton?.clipsToBounds = true
        startButton?.setNeedsDisplay()
        
    }

    
    @objc func tappedButton(sender: UIButton) {
        guard let route = currentRoute else { return }
        let navigationViewController = NavigationViewController(for: route)
        navigationViewController.delegate = self
        
        // This allows the developer to simulate the route.
        // Note: If copying and pasting this code in your own project,
        // comment out `simulationIsEnabled` as it is defined elsewhere in this project.
        if simulationIsEnabled {
            navigationViewController.routeController.locationManager = SimulatedLocationManager(route: route)
        }
        
        present(navigationViewController, animated: true, completion: nil)
    }
    
     @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        let spot = gesture.location(in: mapView)
        guard let location = mapView?.convert(spot, toCoordinateFrom: mapView) else { return }
        
        requestRoute(destination: location)
    }

    func requestRoute(destination: CLLocationCoordinate2D) {
        guard let userLocation = mapView?.userLocation!.location else { return }
        let userWaypoint = Waypoint(location: userLocation, heading: mapView?.userLocation?.heading, name: "user")
        let destinationWaypoint = Waypoint(coordinate: destination)
        
        let options = NavigationRouteOptions(waypoints: [userWaypoint, destinationWaypoint])
        
        Directions.shared.calculate(options) { (waypoints, routes, error) in
            guard let routes = routes else { return }
            self.routes = routes
            self.startButton?.isHidden = false
            self.mapView?.showRoutes(routes)
            self.mapView?.showWaypoints(self.currentRoute!)
        }
    }
    
    // Delegate method called when the user selects a route
    func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        self.currentRoute = route
    }
}
```
