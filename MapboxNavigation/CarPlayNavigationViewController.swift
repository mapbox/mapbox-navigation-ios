import Foundation
import MapboxDirections
import MapboxCoreNavigation

class CarPlayNavigationViewController: UIViewController, RouteControllerDelegate, StyleManagerDelegate {
    func locationFor(styleManager: StyleManager) -> CLLocation {
        return CLLocation(latitude: 0, longitude: 0)
    }
    
    var route: Route
    
    var routeController: RouteController
    
    var directions: Directions
    
    var styleManager: StyleManager!
    
    var mapView: NavigationMapView!
    
    public init(for route: Route,
                directions: Directions,
                styles: [Style] = [DayStyle(), NightStyle()],
                locationManager: NavigationLocationManager = NavigationLocationManager()) {
        
        self.routeController = RouteController(along: route, directions: directions, locationManager: locationManager)
        self.routeController.usesDefaultUserInterface = true
        self.route = route
        self.directions = directions
        
        super.init(nibName: nil, bundle: nil)
        self.styleManager = StyleManager(self)
        self.styleManager.styles = styles
        self.routeController.delegate = self
        
        routeController.resume()
        resumeNotifications()
        
        NavigationSettings.shared.distanceUnit = route.routeOptions.locale.usesMetric ? .kilometer : .mile
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let mapView = MGLMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        mapView.styleURL = MGLStyle.outdoorsStyleURL
        
        // Mauna Kea, Hawaii
        let center = CLLocationCoordinate2D(latitude: 19.820689, longitude: -155.468038)
        
        // Optionally set a starting point.
        mapView.setCenter(center, zoomLevel: 7, direction: 0, animated: false)
        
        view.addSubview(mapView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        suspendNotifications()
        routeController.suspendLocationUpdates()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_ :)), name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(rerouted(_:)), name: .routeControllerDidReroute, object: nil)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerWillReroute, object: nil)
    }
    
    @objc func progressDidChange(_ notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as! RouteProgress
        let location = notification.userInfo![RouteControllerNotificationUserInfoKey.locationKey] as! CLLocation
        
        // Add maneuver arrow
        if routeProgress.currentLegProgress.followOnStep != nil {
            mapView.addArrow(route: routeProgress.route, legIndex: routeProgress.legIndex, stepIndex: routeProgress.currentLegProgress.stepIndex + 1)
        } else {
            mapView.removeArrow()
        }
        
        // Update the user puck
        mapView.updateCourseTracking(location: location, animated: true)
    }
}

