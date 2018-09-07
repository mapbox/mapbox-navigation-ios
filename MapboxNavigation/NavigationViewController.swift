import UIKit
import MapboxCoreNavigation
import MapboxDirections
import Mapbox

/**
 The `NavigationViewControllerDelegate` provides methods for configuring the map view shown by a `NavigationViewController` and responding to the cancellation of a navigation session.
 */
@objc(MBNavigationViewControllerDelegate)
public protocol NavigationViewControllerDelegate: VisualInstructionDelegate {
    /**
     Called when the navigation view controller is dismissed, such as when the user ends a trip.
     
     - parameter navigationViewController: The navigation view controller that was dismissed.
     - parameter canceled: True if the user dismissed the navigation view controller by tapping the Cancel button; false if the navigation view controller dismissed by some other means.
     */
    @objc optional func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool)
    
    /**
     Called when the user arrives at the destination waypoint for a route leg.
     
     This method is called when the navigation view controller arrives at the waypoint. You can implement this method to prevent the navigation view controller from automatically advancing to the next leg. For example, you can and show an interstitial sheet upon arrival and pause navigation by returning `false`, then continue the route when the user dismisses the sheet. If this method is unimplemented, the navigation view controller automatically advances to the next leg when arriving at a waypoint.
     
     - postcondition: If you return `false` within this method, you must manually advance to the next leg: obtain the value of the `routeController` and its `RouteController.routeProgress` property, then increment the `RouteProgress.legIndex` property.
     - parameter navigationViewController: The navigation view controller that has arrived at a waypoint.
     - parameter waypoint: The waypoint that the user has arrived at.
     - returns: True to automatically advance to the next leg, or false to remain on the now completed leg.
     */
    @objc(navigationViewController:didArriveAtWaypoint:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool

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
    optional func navigationViewController(_ navigationViewController: NavigationViewController, willRerouteFrom location: CLLocation?)
    
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
     
     If this method is unimplemented, the navigation view controller’s map view draws the route line using an `MGLLineStyleLayer`.
     */
    @objc optional func navigationViewController(_ navigationViewController: NavigationViewController, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Returns an `MGLStyleLayer` that determines the appearance of the route line’s casing.
     
     If this method is unimplemented, the navigation view controller’s map view draws the route line’s casing using an `MGLLineStyleLayer` whose width is greater than that of the style layer returned by `navigationViewController(_:routeStyleLayerWithIdentifier:source:)`.
     */
    @objc optional func navigationViewController(_ navigationViewController: NavigationViewController, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Returns an `MGLShape` that represents the path of the route line.
     
     If this method is unimplemented, the navigation view controller’s map view represents the route line using an `MGLPolylineFeature` based on `route`’s `coordinates` property.
     */
    @objc(navigationViewController:shapeForRoutes:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, shapeFor routes: [Route]) -> MGLShape?
    
    /**
     Returns an `MGLShape` that represents the path of the route line’s casing.
     
     If this method is unimplemented, the navigation view controller’s map view represents the route line’s casing using an `MGLPolylineFeature` identical to the one returned by `navigationViewController(_:shapeFor:)`.
     */
    @objc(navigationViewController:simplifiedShapeForRoute:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, simplifiedShapeFor route: Route) -> MGLShape?
    
    /*
     Returns an `MGLStyleLayer` that marks the location of each destination along the route when there are multiple destinations. The returned layer is added to the map below the layer returned by `navigationViewController(_:waypointSymbolStyleLayerWithIdentifier:source:)`.
     
     If this method is unimplemented, the navigation view controller’s map view marks each destination waypoint with a circle.
     */
    @objc optional func navigationViewController(_ navigationViewController: NavigationViewController, waypointStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /*
     Returns an `MGLStyleLayer` that places an identifying symbol on each destination along the route when there are multiple destinations. The returned layer is added to the map above the layer returned by `navigationViewController(_:waypointStyleLayerWithIdentifier:source:)`.
     
     If this method is unimplemented, the navigation view controller’s map view labels each destination waypoint with a number, starting with 1 at the first destination, 2 at the second destination, and so on.
     */
    @objc optional func navigationViewController(_ navigationViewController: NavigationViewController, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer?
    
    /**
     Returns an `MGLShape` that represents the destination waypoints along the route (that is, excluding the origin).
     
     If this method is unimplemented, the navigation map view represents the route waypoints using `navigationViewController(_:shapeFor:legIndex:)`.
     */
    @objc(navigationViewController:shapeForWaypoints:legIndex:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, shapeFor waypoints: [Waypoint], legIndex: Int) -> MGLShape?
    
    /**
     Called when the user taps to select a route on the navigation view controller’s map view.
     - parameter navigationViewController: The navigation view controller presenting the route that the user selected.
     - parameter route: The route on the map that the user selected.
     */
    @objc(navigationViewController:didSelectRoute:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, didSelect route: Route)
    
    /**
     Return an `MGLAnnotationImage` that represents the destination marker.
     
     If this method is unimplemented, the navigation view controller’s map view will represent the destination annotation with the default marker.
     */
    @objc(navigationViewController:imageForAnnotation:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage?
    
    /**
     Returns a view object to mark the given point annotation object on the map.
     
     The user location annotation view can also be customized via this method. When annotation is an instance of `MGLUserLocation`, return an instance of `MGLUserLocationAnnotationView` (or a subclass thereof). Note that when `NavigationMapView.tracksUserCourse` is set to `true`, the navigation view controller’s map view uses a distinct user course view; to customize it, set the `NavigationMapView.userCourseView` property of the map view stored by the `NavigationViewController.mapView` property.
     */
    @objc(navigationViewController:viewForAnnotation:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, viewFor annotation: MGLAnnotation) -> MGLAnnotationView?
    
    /**
     Returns the center point of the user course view in screen coordinates relative to the map view.
     */
    @objc optional func navigationViewController(_ navigationViewController: NavigationViewController, mapViewUserAnchorPoint mapView: NavigationMapView) -> CGPoint
    
    /**
     Allows the delegate to decide whether to ignore a location update.
     
     This method is called on every location update. By default, the navigation view controller ignores certain location updates that appear to be unreliable, as determined by the `CLLocation.isQualified` property.
     
     - parameter navigationViewController: The navigation view controller that discarded the location.
     - parameter location: The location that will be discarded.
     - returns: If `true`, the location is discarded and the `NavigationViewController` will not consider it. If `false`, the location will not be thrown out.
     */
    @objc(navigationViewController:shouldDiscardLocation:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, shouldDiscard location: CLLocation) -> Bool
    
    /**
     Called to allow the delegate to customize the contents of the road name label that is displayed towards the bottom of the map view.
     
     This method is called on each location update. By default, the label displays the name of the road the user is currently traveling on.
     
     - parameter navigationViewController: The navigation view controller that will display the road name.
     - parameter location: The user’s current location.
     - returns: The road name to display in the label, or nil to hide the label.
     */
    @objc(navigationViewController:roadNameAtLocation:)
    optional func navigationViewController(_ navigationViewController: NavigationViewController, roadNameAt location: CLLocation) -> String?
}

/**
 `NavigationViewController` is fully featured, turn by turn navigation UI.
 
 It provides step by step instructions, an overview of all steps for the given route and support for basic styling.
 */
@objc(MBNavigationViewController)
open class NavigationViewController: UIViewController {
    
    /** 
     A `Route` object constructed by [MapboxDirections](https://mapbox.github.io/mapbox-navigation-ios/directions/).
     
     In cases where you need to update the route after navigation has started you can set a new `route` here and `NavigationViewController` will update its UI accordingly.
     */
    @objc public var route: Route {
        get {
            return navigationService.route
        }
        set {
            navigationService.route = newValue
            NavigationSettings.shared.distanceUnit = route.routeOptions.locale.usesMetric ? .kilometer : .mile
            mapViewController?.notifyDidReroute(route: route)
        }
    }
    
    /**
     An instance of `Directions` need for rerouting. See [Mapbox Directions](https://mapbox.github.io/mapbox-navigation-ios/directions/) for further information.
     */
    @objc public var directions: Directions {
        return navigationService!.directions
    }
    
    /**
     An optional `MGLMapCamera` you can use to improve the initial transition from a previous viewport and prevent a trigger from an excessive significant location update.
     */
    @objc public var pendingCamera: MGLMapCamera?
    
    /**
     An instance of `MGLAnnotation` representing the origin of your route.
     */
    @objc public var origin: MGLAnnotation?
    
    /**
     The receiver’s delegate.
     */
    @objc public weak var delegate: NavigationViewControllerDelegate?
    
    /**
     Provides access to various speech synthesizer options.
     
     See `RouteVoiceController` for more information.
     */
    @objc public var voiceController: RouteVoiceController!
    
    /**
     Provides all routing logic for the user.

     See `RouteController` for more information.
     */
    @objc public var navigationService: NavigationService! {
        didSet {
            mapViewController?.navigationService = navigationService
        }
    }
    
    /**
     The main map view displayed inside the view controller.
     
     - note: Do not change this map view’s delegate.
     */
    @objc public var mapView: NavigationMapView? {
        get {
            return mapViewController?.mapView
        }
    }
    
    /**
     Determines whether the user location annotation is moved from the raw user location reported by the device to the nearest location along the route.
     
     By default, this property is set to `true`, causing the user location annotation to be snapped to the route.
     */
    @objc public var snapsUserLocationAnnotationToRoute = true
    
    /**
     Toggles sending of UILocalNotification upon upcoming steps when application is in the background. Defaults to `true`.
     */
    @objc public var sendsNotifications: Bool = true
    
    /**
     Shows a button that allows drivers to report feedback such as accidents, closed roads,  poor instructions, etc. Defaults to `true`.
     */
    @objc public var showsReportFeedback: Bool = true {
        didSet {
            mapViewController?.reportButton.isHidden = !showsReportFeedback
            showsEndOfRouteFeedback = showsReportFeedback
        }
    }
    
    /**
    Shows End of route Feedback UI when the route controller arrives at the final destination. Defaults to `true.`
    */
    @objc public var showsEndOfRouteFeedback: Bool = true {
        didSet {
            mapViewController?.showsEndOfRoute = showsEndOfRouteFeedback
        }
    }
    
    /**
     If true, the map style and UI will automatically be updated given the time of day.
     */
    @objc public var automaticallyAdjustsStyleForTimeOfDay = true {
        didSet {
            styleManager.automaticallyAdjustsStyleForTimeOfDay = automaticallyAdjustsStyleForTimeOfDay
        }
    }

    /**
     If `true`, `UIApplication.isIdleTimerDisabled` is set to `true` in `viewWillAppear(_:)` and `false` in `viewWillDisappear(_:)`. If your application manages the idle timer itself, set this property to `false`.
     */
    @objc public var shouldManageApplicationIdleTimer = true
    
    var mapViewController: RouteMapViewController?
    
    /**
     A Boolean value that determines whether the map annotates the locations at which instructions are spoken for debugging purposes.
     */
    @objc public var annotatesSpokenInstructions = false
    
    var styleManager: StyleManager!
    
    var currentStatusBarStyle: UIStatusBarStyle = .default {
        didSet {
            mapViewController?.instructionsBannerView.backgroundColor = InstructionsBannerView.appearance().backgroundColor
            mapViewController?.instructionsBannerContentView.backgroundColor = InstructionsBannerContentView.appearance().backgroundColor
        }
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return currentStatusBarStyle
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private var traversingTunnel = false
    
    /**
     Initializes a `NavigationViewController` that provides turn by turn navigation for the given route. A optional `direction` object is needed for  potential rerouting.

     See [Mapbox Directions](https://mapbox.github.io/mapbox-navigation-ios/directions/) for further information.
     */
    @objc(initWithRoute:styles:navigationService:voiceController:)
    required public init(for route: Route,
                         styles: [Style]? = [DayStyle(), NightStyle()],
                         navigationService: NavigationService? = nil,
                         voiceController: RouteVoiceController? = nil) {
        
        super.init(nibName: nil, bundle: nil)
        
        self.navigationService = navigationService ?? MapboxNavigationService(route: route)
        self.navigationService.usesDefaultUserInterface = true
        self.navigationService.delegate = self
        self.navigationService.start()
        self.voiceController = voiceController ?? MapboxVoiceController()
        
        let mapViewController = RouteMapViewController(navigationService: self.navigationService, delegate: self)
        self.mapViewController = mapViewController
        mapViewController.destination = route.legs.last?.destination
        mapViewController.willMove(toParentViewController: self)
        addChildViewController(mapViewController)
        mapViewController.didMove(toParentViewController: self)
        let mapSubview: UIView = mapViewController.view
        mapSubview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mapSubview)
        
        mapSubview.pinInSuperview()
        mapViewController.reportButton.isHidden = !showsReportFeedback
        
        self.styleManager = StyleManager(self)
        self.styleManager.styles = styles ?? [DayStyle(), NightStyle()]
        
        if !(route.routeOptions is NavigationRouteOptions) {
            print("`Route` was created using `RouteOptions` and not `NavigationRouteOptions`. Although not required, this may lead to a suboptimal navigation experience. Without `NavigationRouteOptions`, it is not guaranteed you will get congestion along the route line, better ETAs and ETA label color dependent on congestion.")
        }
    }
    
    deinit {
        suspendNotifications()
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        // Initialize voice controller if it hasn't been overridden.
        // This is optional and lazy so it can be mutated by the developer after init.
        _ = voiceController
        resumeNotifications()
        view.clipsToBounds = true
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if shouldManageApplicationIdleTimer {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        if navigationService.locationManager is SimulatedLocationManager {
            let localized = String.Localized.simulationStatus(speed: 1)
            mapViewController?.statusView.show(localized, showSpinner: false, interactive: true)
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if shouldManageApplicationIdleTimer {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        
        navigationService.stop()
    }
    
    // MARK: Route controller notifications
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(notification:)), name: .routeControllerProgressDidChange, object: navigationService.router)
        NotificationCenter.default.addObserver(self, selector: #selector(didPassInstructionPoint(notification:)), name: .routeControllerDidPassSpokenInstructionPoint, object: navigationService.router)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: navigationService.router)
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidPassSpokenInstructionPoint, object: navigationService.router)
    }
    
    @objc func progressDidChange(notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as! RouteProgress
        let location = notification.userInfo![RouteControllerNotificationUserInfoKey.locationKey] as! CLLocation
        let secondsRemaining = routeProgress.currentLegProgress.currentStepProgress.durationRemaining

        mapViewController?.notifyDidChange(routeProgress: routeProgress, location: location, secondsRemaining: secondsRemaining)
    }
    
    @objc func didPassInstructionPoint(notification: NSNotification) {
        let routeProgress = notification.userInfo![RouteControllerNotificationUserInfoKey.routeProgressKey] as! RouteProgress
        
        mapViewController?.updateCameraAltitude(for: routeProgress)
        
        clearStaleNotifications()
        
        if routeProgress.currentLegProgress.currentStepProgress.durationRemaining <= RouteControllerHighAlertInterval {
            scheduleLocalNotification(about: routeProgress.currentLegProgress.currentStep, legIndex: routeProgress.legIndex, numberOfLegs: routeProgress.route.legs.count)
        }
    }
    
    func scheduleLocalNotification(about step: RouteStep, legIndex: Int?, numberOfLegs: Int?) {
        guard sendsNotifications else { return }
        guard UIApplication.shared.applicationState == .background else { return }
        guard let text = step.instructionsSpokenAlongStep?.last?.text else { return }
        
        let notification = UILocalNotification()
        notification.alertBody = text
        notification.fireDate = Date()
        
        clearStaleNotifications()
        
        UIApplication.shared.cancelAllLocalNotifications()
        UIApplication.shared.scheduleLocalNotification(notification)
    }
    
    func clearStaleNotifications() {
        guard sendsNotifications else { return }
        // Remove all outstanding notifications from notification center.
        // This will only work if it's set to 1 and then back to 0.
        // This way, there is always just one notification.
        UIApplication.shared.applicationIconBadgeNumber = 1
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}

//MARK: - RouteMapViewControllerDelegate
extension NavigationViewController: RouteMapViewControllerDelegate {
    public func navigationMapView(_ mapView: NavigationMapView, routeCasingStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationViewController?(self, routeCasingStyleLayerWithIdentifier: identifier, source: source)
    }
    
    public func navigationMapView(_ mapView: NavigationMapView, routeStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationViewController?(self, routeStyleLayerWithIdentifier: identifier, source: source)
    }
    
    public func navigationMapView(_ mapView: NavigationMapView, didSelect route: Route) {
        delegate?.navigationViewController?(self, didSelect: route)
    }
    
    @objc public func navigationMapView(_ mapView: NavigationMapView, shapeFor routes: [Route]) -> MGLShape? {
        return delegate?.navigationViewController?(self, shapeFor: routes)
    }
    
    @objc public func navigationMapView(_ mapView: NavigationMapView, simplifiedShapeFor route: Route) -> MGLShape? {
        return delegate?.navigationViewController?(self, simplifiedShapeFor: route)
    }
    
    public func navigationMapView(_ mapView: NavigationMapView, waypointStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationViewController?(self, waypointStyleLayerWithIdentifier: identifier, source: source)
    }
    
    public func navigationMapView(_ mapView: NavigationMapView, waypointSymbolStyleLayerWithIdentifier identifier: String, source: MGLSource) -> MGLStyleLayer? {
        return delegate?.navigationViewController?(self, waypointSymbolStyleLayerWithIdentifier: identifier, source: source)
    }
    
    @objc public func navigationMapView(_ mapView: NavigationMapView, shapeFor waypoints: [Waypoint], legIndex: Int) -> MGLShape? {
        return delegate?.navigationViewController?(self, shapeFor: waypoints, legIndex: legIndex)
    }
    
    @objc public func navigationMapView(_ mapView: MGLMapView, imageFor annotation: MGLAnnotation) -> MGLAnnotationImage? {
        return delegate?.navigationViewController?(self, imageFor: annotation)
    }
    
    @objc public func navigationMapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        return delegate?.navigationViewController?(self, viewFor: annotation)
    }
    
    func mapViewControllerDidDismiss(_ mapViewController: RouteMapViewController, byCanceling canceled: Bool) {
        if delegate?.navigationViewControllerDidDismiss?(self, byCanceling: canceled) != nil {
            // The receiver should handle dismissal of the NavigationViewController
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    public func navigationMapViewUserAnchorPoint(_ mapView: NavigationMapView) -> CGPoint {
        return delegate?.navigationViewController?(self, mapViewUserAnchorPoint: mapView) ?? .zero
    }
    
    func mapViewControllerShouldAnnotateSpokenInstructions(_ routeMapViewController: RouteMapViewController) -> Bool {
        return annotatesSpokenInstructions
    }
    
    @objc func mapViewController(_ mapViewController: RouteMapViewController, roadNameAt location: CLLocation) -> String? {
        guard let roadName = delegate?.navigationViewController?(self, roadNameAt: location) else {
            return nil
        }
        return roadName
    }
    
    @objc public func label(_ label: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString? {
        return delegate?.label?(label, willPresent: instruction, as: presented)
    }
}

//MARK: - RouteControllerDelegate
extension NavigationViewController: NavigationServiceDelegate {
    
    @objc public func navigationService(_ service: NavigationService, shouldRerouteFrom location: CLLocation) -> Bool {
        return delegate?.navigationViewController?(self, shouldRerouteFrom: location) ?? true
    }
    
    @objc public func navigationService(_ service: NavigationService, willRerouteFrom location: CLLocation) {
        delegate?.navigationViewController?(self, willRerouteFrom: location)
    }
    
    @objc public func navigationService(_ service: NavigationService, didRerouteAlong route: Route) {
        mapViewController?.notifyDidReroute(route: route)
        delegate?.navigationViewController?(self, didRerouteAlong: route)
    }
    
    @objc public func navigationService(_ service: NavigationService, didFailToRerouteWith error: Error) {
        delegate?.navigationViewController?(self, didFailToRerouteWith: error)
    }
    
    @objc public func navigationService(_ service: NavigationService, shouldDiscard location: CLLocation) -> Bool {
        return delegate?.navigationViewController?(self, shouldDiscard: location) ?? true
    }
    
    @objc public func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        
        //Check to see if we're in a tunnel.
        checkTunnelState(at: location, along: progress)

        // If the user has arrived, don't snap the user puck.
        // In the case the user drives beyond the waypoint,
        // we should accurately depict this.
        
        // Delegate method is trying to figure
        let shouldPreventReroutesWhenArrivingAtWaypoint = service.delegate?.navigationService?(service, shouldPreventReroutesWhenArrivingAt: service.routeProgress.currentLeg.destination) ?? true
        let userHasArrivedAndShouldPreventRerouting = shouldPreventReroutesWhenArrivingAtWaypoint && !service.routeProgress.currentLegProgress.userHasArrivedAtWaypoint
        
        if snapsUserLocationAnnotationToRoute,
            userHasArrivedAndShouldPreventRerouting {
            mapViewController?.mapView.updateCourseTracking(location: location, animated: true)
            mapViewController?.labelCurrentRoad(at: rawLocation, for: location)
        } else {
            mapViewController?.mapView.updateCourseTracking(location: rawLocation, animated: true)
            mapViewController?.labelCurrentRoad(at: rawLocation)
        }
    }
    
    @objc public func navigationService(_ service: NavigationService, didArriveAt waypoint: Waypoint) -> Bool {
        let advancesToNextLeg = delegate?.navigationViewController?(self, didArriveAt: waypoint) ?? true
        
        if service.routeProgress.isFinalLeg && advancesToNextLeg && showsEndOfRouteFeedback {
            self.mapViewController?.showEndOfRoute { _ in }
        }
        return advancesToNextLeg

    }
    
    private func checkTunnelState(at location: CLLocation, along progress: RouteProgress) {
        let inTunnel = MapboxNavigationService.isInTunnel(at: location, along: progress)
        
        if !traversingTunnel, inTunnel { // we're entering
            traversingTunnel = true
            styleManager.applyStyle(type: .night)
        }
        
        if traversingTunnel, !inTunnel { //we're exiting
            traversingTunnel = false
            styleManager.timeOfDayChanged()
        }
    }
}


extension NavigationViewController: StyleManagerDelegate {
    
    public func locationFor(styleManager: StyleManager) -> CLLocation? {
        if let location = navigationService.router.location {
            return location
        } else if let firstCoord = route.coordinates?.first {
            return CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
        } else {
            return nil
        }
    }
    
    public func styleManager(_ styleManager: StyleManager, didApply style: Style) {
        if mapView?.styleURL != style.mapStyleURL {
            mapView?.style?.transition = MGLTransition(duration: 0.5, delay: 0)
            mapView?.styleURL = style.mapStyleURL
        }
        
        currentStatusBarStyle = style.statusBarStyle ?? .default
        setNeedsStatusBarAppearanceUpdate()
    }
    
    public func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) {
        mapView?.reloadStyle(self)
    }
}
