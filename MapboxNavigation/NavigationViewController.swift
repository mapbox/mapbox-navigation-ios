import UIKit
import MapboxCoreNavigation
import MapboxDirections
import Mapbox
import Pulley

@objc(MBNavigationPulleyViewController)
public class NavigationPulleyViewController: PulleyViewController {}

/**
 The `NavigationViewControllerDelegate` provides methods for configuring the map view shown by a `NavigationViewController` and responding to the cancellation of a navigation session.
 */
@objc(MBNavigationViewControllerDelegate)
public protocol NavigationViewControllerDelegate {
    /**
     Called when the user exits a route and dismisses the navigation view controller by tapping the Cancel button.
     */
    @objc optional func navigationViewControllerDidCancelNavigation(_ : NavigationViewController)
    
    /**
     Called when the user arrives at the destination.
     */
    @objc optional func navigationViewController(_ navigationViewController : NavigationViewController, didArriveAt destination: MGLAnnotation)

    /**
     Called when `RouteControllerShouldReroute` is sent from `RouteController`.

     If this method is unimplemented `NavigationViewController` will automatically reroute. If this method is implemented,
     it's responsible for handling rerouting.
    */
    @objc(navigationViewController:shouldRerouteFromLocation:) optional func navigationViewController(_ : NavigationViewController, shouldRerouteFrom location: CLLocation)
    
    /**
     Returns an `MGLStyleLayer` that determines the appearance of the route line.
     
     If this method is unimplemented, the navigation map view draws the route line using an `MGLLineStyleLayer`.
     */
    @objc optional func navigationMapView(_ mapView: NavigationMapView, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Returns an `MGLStyleLayer` that determines the appearance of the route line’s casing.
     
     If this method is unimplemented, the navigation map view draws the route line’s casing using an `MGLLineStyleLayer` whose width is greater than that of the style layer returned by `navigationMapView(_:routeStyleLayerWithIdentifier:source:)`.
     */
    @objc optional func navigationMapView(_ mapView: NavigationMapView, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Returns an `MGLShape` that represents the path of the route line.
     
     If this method is unimplemented, the navigation map view represents the route line using an `MGLPolylineFeature` based on `route`’s `coordinates` property.
     */
    @objc optional func navigationMapView(_ mapView: NavigationMapView, shapeDescribing route: Route) -> MGLShape?
    
    /**
     Returns an `MGLShape` that represents the path of the route line’s casing.
     
     If this method is unimplemented, the navigation map view represents the route line’s casing using an `MGLPolylineFeature` identical to the one returned by `navigationMapView(_:shapeDescribing:)`.
     */
    @objc optional func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeDescribing route: Route) -> MGLShape?
}

/**
 `NavigationViewController` is fully featured, turn by turn navigation UI.
 
 It provides step by step instructions, an overview of all steps
 for the given route and support for basic styling.
 */
@objc(MBNavigationViewController)
public class NavigationViewController: NavigationPulleyViewController, RouteMapViewControllerDelegate {
    
    // A `route` object constructed by [MapboxDirections.swift](https://github.com/mapbox/MapboxDirections.swift)
    public var route: Route! {
        didSet {
            setupRouteController()
        }
    }
    
    /** 
     `destination` is an instance of `MGLAnnotation` that will be showned on
     on the destination of your route. The last coordinate of the route will be
     used if no destination is given.
    */
    public var destination: MGLAnnotation!
    
    /**
     `directions` is an instance of `Directions` need for rerouting.
     See [MapboxDirections.swift](https://github.com/mapbox/MapboxDirections.swift)
     for further information.
     */
    public var directions: Directions!
    
    /**
     `pendingCamera` is an optional `MGLMapCamera` you can use to improve
     the initial transition from a previous viewport and prevent a trigger
     from an excessive significant location update.
     */
    public var pendingCamera: MGLMapCamera?
    
    /**
     `origin` is an instance of `MGLAnnotation` representing the origin of your route.
     */
    public var origin: MGLAnnotation?
    
    /**
     The receiver’s delegate.
     */
    public var navigationDelegate: NavigationViewControllerDelegate?
    
    /**
     `voiceController` provides access to various speech synthesizer options.
     
     See `RouteVoiceController` for more information.
     */
    public var voiceController: RouteVoiceController? = RouteVoiceController()
    
    /**
     `routeController` provides all routing logic for the user.

     See `RouteController` for more information
     */
    public var routeController: RouteController!
    
    /**
     `simulate` provides simulated location updates along the given route.
     */
    public var simulatesLocationUpdates: Bool = false {
        didSet {
            routeController.simulatesLocationUpdates = simulatesLocationUpdates
        }
    }
    
    /**
     `mapView` provides access to the navigation's `MGLMapView` with all its styling capabilities.
     
     Note that you should not change the `mapView`'s delegate.
     */
    public var mapView: MGLMapView? {
        get {
            return mapViewController?.mapView
        }
    }
    
    /**
     `sendNotifications` toggle sending of UILocalNotification upon upcoming
     steps when application is in the background.
     */
    public var sendNotifications: Bool = true
    
    var tableViewController: RouteTableViewController?
    var mapViewController: RouteMapViewController?
    
    var routeTask: URLSessionDataTask?
    let routeStepFormatter = RouteStepFormatter()
    
    var lastReRouteLocation: CLLocation?
    
    var simulation: SimulatedRoute?
    
    required public init?(coder aDecoder: NSCoder) {
        Style.defaultStyle.apply()
        super.init(coder: aDecoder)
    }
    
    required public init(contentViewController: UIViewController, drawerViewController: UIViewController) {
        fatalError("init(contentViewController:drawerViewController:) has not been implemented. " +
                   "Use init(for:directions:) if you are instantiating programmatically " +
                   "or a storyboard reference to Navigation if you are using storyboards.")
    }
    
    /**
     Initializes a `NavigationViewController` that provides turn by turn navigation
     for the given route. A optional `direction` object is needed for  potential
     rerouting.

     See [MapboxDirections.swift](https://github.com/mapbox/MapboxDirections.swift)
     for further information.
     */
    @objc(initWithRoute:directions:)
    required public init(for route: Route,  directions: Directions = Directions.shared) {
        Style.defaultStyle.apply()
        
        let storyboard = UIStoryboard(name: "Navigation", bundle: Bundle.navigationUI)
        let mapViewController = storyboard.instantiateViewController(withIdentifier: "RouteMapViewController") as! RouteMapViewController
        let tableViewController = storyboard.instantiateViewController(withIdentifier: "RouteTableViewController") as! RouteTableViewController
        
        super.init(contentViewController: mapViewController, drawerViewController: tableViewController)
        
        self.directions = directions
        self.route = route
        self.setupRouteController()
        self.mapViewController = mapViewController
        self.tableViewController = tableViewController
        
        mapViewController.delegate = self
        mapViewController.routeController = routeController
        mapViewController.destination = destination
        
        tableViewController.routeController = routeController
        tableViewController.headerView.delegate = self
    }
    
    deinit {
        suspendNotifications()
        mapViewController?.resetTrackingModeTimer?.invalidate()
        voiceController?.announcementTimer?.invalidate()
    }
    
    override public func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier ?? "" {
        case "MapViewControllerSegueIdentifier":
            if let controller = segue.destination as? RouteMapViewController {
                controller.routeController = routeController
                controller.destination = destination
                mapViewController = controller
                controller.delegate = self
            }
        case "TableViewControllerSegueIdentifier":
            if let controller = segue.destination as? RouteTableViewController {
                controller.headerView.delegate = self
                controller.routeController = routeController
                tableViewController = controller
            }
        default:
            break
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        resumeNotifications()
        self.drawerCornerRadius = 0
        self.delegate = self
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        suspendNotifications()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
        routeController.resume()
        
        if simulatesLocationUpdates {
            guard let coordinates = route.coordinates else { return }
            simulation = SimulatedRoute(along: coordinates)
            simulation?.delegate = self
            simulation?.start()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = false
        routeController.suspendLocationUpdates()
        simulation?.stop()
    }
    
    // MARK: Route controller notifications
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(notification:)), name: RouteControllerProgressDidChange, object: routeController)
        NotificationCenter.default.addObserver(self, selector: #selector(shouldReroute(notification:)), name: RouteControllerShouldReroute, object: routeController)
        NotificationCenter.default.addObserver(self, selector: #selector(alertLevelDidChange(notification:)), name: RouteControllerAlertLevelDidChange, object: routeController)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: RouteControllerProgressDidChange, object: routeController)
        NotificationCenter.default.removeObserver(self, name: RouteControllerShouldReroute, object: routeController)
        NotificationCenter.default.removeObserver(self, name: RouteControllerAlertLevelDidChange, object: routeController)
    }
    
    func progressDidChange(notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
        let location = notification.userInfo![RouteControllerProgressDidChangeNotificationLocationKey] as! CLLocation
        let secondsRemaining = notification.userInfo![RouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey] as! TimeInterval

        mapViewController?.notifyDidChange(routeProgress: routeProgress, location: location, secondsRemaining: secondsRemaining)
        tableViewController?.notifyDidChange(routeProgress: routeProgress)
        
        if routeProgress.currentLegProgress.alertUserLevel == .arrive {
            navigationDelegate?.navigationViewController?(self, didArriveAt: destination)
        }
    }
    
    func shouldReroute(notification: NSNotification) {
        let location = notification.userInfo![RouteControllerNotificationShouldRerouteKey] as! CLLocation

        guard navigationDelegate?.navigationViewController?(self, shouldRerouteFrom: location) == nil else {
            return
        }
        
        if let previousLocation = lastReRouteLocation {
            guard location.distance(from: previousLocation) >= RouteControllerMaximumDistanceBeforeRecalculating else {
                return
            }
        }
        
        routeTask?.cancel()
        
        let options = routeController.routeProgress.route.routeOptions
 
        options.waypoints = [Waypoint(coordinate: location.coordinate), Waypoint(coordinate: destination.coordinate)]
        
        if let firstWaypoint = options.waypoints.first, location.course >= 0 {
            firstWaypoint.heading = location.course
            firstWaypoint.headingAccuracy = 90
        }
        
        routeTask = directions.calculate(options, completionHandler: { [weak self] (waypoints, routes, error) in
            guard let strongSelf = self else {
                return
            }
            
            if let route = routes?.first {
                strongSelf.routeController.routeProgress = RouteProgress(route: route)
                strongSelf.routeController.routeProgress.currentLegProgress.stepIndex = 0
                
                strongSelf.giveLocalNotification(strongSelf.routeController.routeProgress.currentLegProgress.currentStep)
                
                strongSelf.mapViewController?.notifyDidReroute(route: route)
                strongSelf.tableViewController?.notifyDidReroute()
            }
        })
    }
    
    func alertLevelDidChange(notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerAlertLevelDidChangeNotificationRouteProgressKey] as! RouteProgress
        let alertLevel = routeProgress.currentLegProgress.alertUserLevel
        
        mapViewController?.notifyAlertLevelDidChange(routeProgress: routeProgress)
        tableViewController?.notifyAlertLevelDidChange()
        
        if let upComingStep = routeProgress.currentLegProgress.upComingStep, alertLevel == .high {
            giveLocalNotification(upComingStep)
        }
    }
    
    func giveLocalNotification(_ step: RouteStep) {
        guard sendNotifications else { return }
        guard UIApplication.shared.applicationState == .background else { return }
        
        let notification = UILocalNotification()
        notification.alertBody = routeStepFormatter.string(for: step)
        notification.fireDate = Date()
        
        UIApplication.shared.cancelAllLocalNotifications()
        
        // Remove all outstanding notifications from notification center.
        // This will only work if it's set to 1 and then back to 0.
        // This way, there is always just one notification.
        UIApplication.shared.applicationIconBadgeNumber = 0
        UIApplication.shared.applicationIconBadgeNumber = 1
        
        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
    func setupRouteController() {
        if routeController == nil {
            routeController = RouteController(route: route)
            routeController.simulatesLocationUpdates = simulatesLocationUpdates
            
            if Bundle.main.backgroundModeLocationSupported {
                routeController.locationManager.activityType = .automotiveNavigation
                routeController.locationManager.allowsBackgroundLocationUpdates = true
            }
        }
        
        if destination == nil {
            let annotation = MGLPointAnnotation()
            annotation.coordinate = route.coordinates!.last!
            destination = annotation
        }
    }
    
    func navigationMapView(_ mapView: NavigationMapView, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return navigationDelegate?.navigationMapView?(mapView, routeCasingStyleLayerWithIdentifier: identifier, source: source)
    }
    
    func navigationMapView(_ mapView: NavigationMapView, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return navigationDelegate?.navigationMapView?(mapView, routeStyleLayerWithIdentifier: identifier, source: source)
    }
    
    func navigationMapView(_ mapView: NavigationMapView, shapeDescribing route: Route) -> MGLShape? {
        return navigationDelegate?.navigationMapView?(mapView, shapeDescribing: route)
    }
    
    func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeDescribing route: Route) -> MGLShape? {
        return navigationDelegate?.navigationMapView?(mapView, shapeDescribing: route)
    }
}

extension NavigationViewController: RouteTableViewHeaderViewDelegate {
    func didTapCancel() {
        if navigationDelegate?.navigationViewControllerDidCancelNavigation?(self) != nil {
            // The receiver should handle dismissal of the NavigationViewController
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

extension NavigationViewController: PulleyDelegate {
    public func drawerPositionDidChange(drawer: PulleyViewController) {
        switch drawer.drawerPosition {
        case .open:
            tableViewController?.tableView.isScrollEnabled = true
            break
        case .partiallyRevealed:
            tableViewController?.tableView.isScrollEnabled = true
            break
        case .collapsed:
            tableViewController?.tableView.isScrollEnabled = false
            break
        case .closed:
            break
        }
    }
}

extension NavigationViewController: SimulatedRouteDelegate {
    func simulation(_ locationManager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        mapViewController?.mapView.locationManager(locationManager, didUpdateLocations: locations)
        routeController.locationManager(locationManager, didUpdateLocations: locations)
    }
}
