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
     Returns whether the navigation view controller should be allowed to calculate a new route.
     
     If implemented, this method is called as soon as the navigation view controller detects that the user is off the predetermined route. Implement this method to conditionally prevent rerouting. If this method returns `true`, `navigationViewController(_:willRerouteFrom:)` will be called immediately afterwards.
     
     - parameter navigationViewController: The navigation view controller that has detected the need to calculate a new route.
     - parameter location: The user’s current location.
     - returns: True to allow the navigation view controller to calculate a new route; false to keep tracking the current route.
    */
    @objc(navigationViewController:shouldRerouteFromLocation:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, shouldRerouteFrom location: CLLocation) -> Bool
    
    /**
     Called immediately before the navigation view controller calculates a new route.
     
     This method is called after `navigationViewController(_:shouldRerouteFrom:)` is called, simultaneously with the `RouteControllerWillReroute` notification being posted, and before `navigationViewController(_:didRerouteAlong:)` is called.
     
     - parameter navigationViewController: The navigation view controller that will calculate a new route.
     - parameter location: The user’s current location.
     */
    @objc(navigationViewController:willRerouteFromLocation:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, willRerouteFrom location: CLLocation)
    
    /**
     Called immediately after the navigation view controller receives a new route.
     
     This method is called after `navigationViewController(_:willRerouteFrom:)` and simultaneously with the `RouteControllerDidReroute` notification being posted.
     
     - parameter navigationViewController: The navigation view controller that has calculated a new route.
     - parameter route: The new route.
     */
    @objc(navigationViewController:didRerouteAlongRoute:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, didRerouteAlong route: Route)
    
    /**
     Called when the navigation view controller fails to receive a new route.
     
     This method is called after `navigationViewController(_:willRerouteFrom:)` and simultaneously with the `RouteControllerDidFailToReroute` notification being posted.
     
     - parameter navigationViewController: The navigation view controller that has calculated a new route.
     - parameter error: An error raised during the process of obtaining a new route.
     */
    @objc(navigationViewController:didFailToRerouteWithError:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, didFailToRerouteWith error: Error)
    
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
    
    let routeStepFormatter = RouteStepFormatter()
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(alertLevelDidChange(notification:)), name: RouteControllerAlertLevelDidChange, object: routeController)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: RouteControllerProgressDidChange, object: routeController)
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
            routeController = RouteController(along: route, directions: directions)
            routeController.delegate = self
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

extension NavigationViewController: RouteControllerDelegate {
    public func routeController(_ routeController: RouteController, shouldRerouteFrom location: CLLocation) -> Bool {
        return navigationDelegate?.navigationViewController?(self, shouldRerouteFrom: location) ?? true
    }
    
    public func routeController(_ routeController: RouteController, willRerouteFrom location: CLLocation) {
        navigationDelegate?.navigationViewController?(self, willRerouteFrom: location)
    }
    
    public func routeController(_ routeController: RouteController, didRerouteAlong route: Route) {
        giveLocalNotification(routeController.routeProgress.currentLegProgress.currentStep)
        
        mapViewController?.notifyDidReroute(route: route)
        tableViewController?.notifyDidReroute()
        
        navigationDelegate?.navigationViewController?(self, didRerouteAlong: route)
    }
    
    public func routeController(_ routeController: RouteController, didFailToRerouteWith error: Error) {
        navigationDelegate?.navigationViewController?(self, didFailToRerouteWith: error)
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
