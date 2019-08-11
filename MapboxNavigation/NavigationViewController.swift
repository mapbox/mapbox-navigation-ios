import UIKit
import MapboxCoreNavigation
import MapboxDirections
import MapboxSpeech
import Mapbox
#if canImport(CarPlay)
import CarPlay
#endif

/**
 A ContainerViewController is any UIViewController that conforms to the NavigationComponent messaging protocol.
 - seealso: NavigationComponent
 */
public typealias ContainerViewController = UIViewController & NavigationComponent

/**
 `NavigationViewController` is a fully-featured turn-by-turn navigation UI.
 
 It provides step by step instructions, an overview of all steps for the given route and support for basic styling.
 
 - seealso: CarPlayNavigationViewController
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
            
            navigationComponents.forEach { $0.navigationService?(navigationService, didRerouteAlong: newValue, at: nil, proactive: false) }
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

     See `NavigationService` for more information.
     */
    @objc private(set) public var navigationService: NavigationService! {
        didSet {
            mapViewController?.navService = navigationService
        }
    }
    
    /**
     The main map view displayed inside the view controller.
     
     - note: Do not change this map view’s `NavigationMapView.navigationMapDelegate` property; instead, implement the corresponding methods on `NavigationViewControllerDelegate`.
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
    
    /**
     Bool which should be set to true if a CarPlayNavigationView is also being used.
     */
    @objc public var isUsedInConjunctionWithCarPlayWindow = false {
        didSet {
            mapViewController?.isUsedInConjunctionWithCarPlayWindow = isUsedInConjunctionWithCarPlayWindow
        }
    }
    
    var isConnectedToCarPlay: Bool {
        if #available(iOS 12.0, *) {
            return CarPlayManager.isConnected
        } else {
            return false
        }
    }
    
    var mapViewController: RouteMapViewController?
    
    var bottomViewController: ContainerViewController?
    
    var navigationComponents: [NavigationComponent] {
        var components: [NavigationComponent] = []
        if let mvc = mapViewController {
            components.append(mvc)
        }
        if let bottomViewController = bottomViewController {
            components.append(bottomViewController)
        }
        return components
    }
    
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
     
     - parameter route: The route to navigate along.
     - parameter options: The navigation options to use for the navigation session. See `NavigationOptions`.
     */
    @objc(initWithRoute:options:)
    required public init(for route: Route,
                         options: NavigationOptions? = nil) {
        
        super.init(nibName: nil, bundle: nil)
        
        self.navigationService = options?.navigationService ?? MapboxNavigationService(route: route)
        self.navigationService.usesDefaultUserInterface = true
        self.navigationService.delegate = self
        self.voiceController = options?.voiceController ?? MapboxVoiceController(navigationService: navigationService, speechClient: SpeechSynthesizer(accessToken: navigationService?.directions.accessToken))

        NavigationSettings.shared.distanceUnit = route.routeOptions.locale.usesMetric ? .kilometer : .mile
        
        let bottomBanner = options?.bottomBanner ?? {
            let viewController = BottomBannerViewController()
            viewController.delegate = self
            return viewController
        }()
        bottomViewController = bottomBanner

        let mapViewController = RouteMapViewController(navigationService: self.navigationService, delegate: self, bottomBanner: bottomBanner)
        self.mapViewController = mapViewController
        mapViewController.destination = route.legs.last?.destination
        mapViewController.view.translatesAutoresizingMaskIntoConstraints = false

        
        embed(mapViewController, in: view) { (parent, map) -> [NSLayoutConstraint] in
            return map.view.constraintsForPinning(to: parent.view)
        }
        

        
        //Do not start the navigation session until after you create the MapViewController, otherwise you'll miss important messages.
        self.navigationService.start()
        
        mapViewController.view.pinInSuperview()
        mapViewController.reportButton.isHidden = !showsReportFeedback
        
        styleManager = StyleManager()
        styleManager.delegate = self
        styleManager.styles = options?.styles ?? [DayStyle(), NightStyle()]
        
        if !(route.routeOptions is NavigationRouteOptions) {
            print("`Route` was created using `RouteOptions` and not `NavigationRouteOptions`. Although not required, this may lead to a suboptimal navigation experience. Without `NavigationRouteOptions`, it is not guaranteed you will get congestion along the route line, better ETAs and ETA label color dependent on congestion.")
        }
    }
    
    /**
    Initializes a navigation view controller with the given route and navigation service.
     
     - parameter route: The route to navigate along.
     - parameter navigationService: The navigation service that manages navigation along the route.
     */
    convenience init(route: Route, navigationService service: NavigationService) {
        let options = NavigationOptions(navigationService: service)
        self.init(for: route, options: options)
    }
    
    deinit {
        navigationService.stop()
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        // Initialize voice controller if it hasn't been overridden.
        // This is optional and lazy so it can be mutated by the developer after init.
        _ = voiceController
        view.clipsToBounds = true
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if shouldManageApplicationIdleTimer {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if shouldManageApplicationIdleTimer {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        
    }
    
    // MARK: Containerization
    
    func embed(_ child: UIViewController, in container: UIView, constrainedBy constraints: ((NavigationViewController, UIViewController) -> [NSLayoutConstraint])?) {
        child.willMove(toParent: self)
        addChild(child)
        container.addSubview(child.view)
        if let childConstraints: [NSLayoutConstraint] = constraints?(self, child) {
            view.addConstraints(childConstraints)
        }
        child.didMove(toParent: self)
    }
    
    // MARK: Route controller notifications
    
    func scheduleLocalNotification(about step: RouteStep) {
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
    
    
    //Still Kept around for the EORVC. On it's way out.
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

//MARK: - NavigationServiceDelegate
extension NavigationViewController: NavigationServiceDelegate {
    
    @objc public func navigationService(_ service: NavigationService, shouldRerouteFrom location: CLLocation) -> Bool {
        return delegate?.navigationViewController?(self, shouldRerouteFrom: location) ?? true
    }
    
    @objc public func navigationService(_ service: NavigationService, willRerouteFrom location: CLLocation) {
        delegate?.navigationViewController?(self, willRerouteFrom: location)
    }
    
    @objc public func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        for component in navigationComponents {
            component.navigationService?(service, didRerouteAlong: route, at: location, proactive: proactive)
        }

        delegate?.navigationViewController?(self, didRerouteAlong: route)
    }
    
    @objc public func navigationService(_ service: NavigationService, didFailToRerouteWith error: Error) {
        for component in navigationComponents {
            component.navigationService?(service, didFailToRerouteWith: error)
        }

        delegate?.navigationViewController?(self, didFailToRerouteWith: error)
    }
    
    @objc public func navigationService(_ service: NavigationService, shouldDiscard location: CLLocation) -> Bool {
        return delegate?.navigationViewController?(self, shouldDiscard: location) ?? true
    }
    
    @objc public func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        
        //Check to see if we're in a tunnel.
        checkTunnelState(at: location, along: progress)
        
        
        //Pass the message onto our navigation components
        for component in navigationComponents {
            component.navigationService?(service, didUpdate: progress, with: location, rawLocation: rawLocation)
        }

        // If the user has arrived, don't snap the user puck.
        // In the case the user drives beyond the waypoint,
        // we should accurately depict this.
        
        let destination = progress.currentLeg.destination
        let shouldPrevent = navigationService.delegate?.navigationService?(navigationService, shouldPreventReroutesWhenArrivingAt: destination) ?? RouteController.DefaultBehavior.shouldPreventReroutesWhenArrivingAtWaypoint
        let userHasArrivedAndShouldPreventRerouting = shouldPrevent && !progress.currentLegProgress.userHasArrivedAtWaypoint
        
        if snapsUserLocationAnnotationToRoute,
            userHasArrivedAndShouldPreventRerouting {
            mapViewController?.labelCurrentRoad(at: rawLocation, for: location)
        } else  {
            mapViewController?.labelCurrentRoad(at: rawLocation)
        }
        
        if snapsUserLocationAnnotationToRoute,
            userHasArrivedAndShouldPreventRerouting {
            mapViewController?.mapView.updateCourseTracking(location: location, animated: true)
        }
    }
    
    @objc public func navigationService(_ service: NavigationService, didPassSpokenInstructionPoint instruction: SpokenInstruction, routeProgress: RouteProgress) {
        navigationComponents.forEach { $0.navigationService?(service, didPassSpokenInstructionPoint: instruction, routeProgress: routeProgress) }
        
        clearStaleNotifications()
        
        if routeProgress.currentLegProgress.currentStepProgress.durationRemaining <= RouteControllerHighAlertInterval {
            scheduleLocalNotification(about: routeProgress.currentLegProgress.currentStep)
        }
    }
    
    @objc public func navigationService(_ service: NavigationService, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress) {
        navigationComponents.forEach { $0.navigationService?(service, didPassVisualInstructionPoint: instruction, routeProgress: routeProgress) }
    }
    
    
    
    
    @objc public func navigationService(_ service: NavigationService, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance) {
        delegate?.navigationViewController?(self, willArriveAt: waypoint, after: remainingTimeInterval, distance: distance)
    }
    
    @objc public func navigationService(_ service: NavigationService, didArriveAt waypoint: Waypoint) -> Bool {
        let advancesToNextLeg = delegate?.navigationViewController?(self, didArriveAt: waypoint) ?? true
        
        if service.routeProgress.isFinalLeg && advancesToNextLeg && showsEndOfRouteFeedback {
            showEndOfRouteFeedback()
        }
        return advancesToNextLeg

    }
    
    @objc public func showEndOfRouteFeedback(duration: TimeInterval = 1.0, completionHandler: ((Bool) -> Void)? = nil) {
        guard let mapController = mapViewController else { return }
        mapController.showEndOfRoute(duration: duration, completion: completionHandler)
    }

    @objc public func navigationService(_ service: NavigationService, willBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        switch service.simulationMode {
        case .always:
            let localized = String.Localized.simulationStatus(speed: 1)
            mapViewController?.statusView.show(localized, showSpinner: false, interactive: true)
        default:
            return
        }
    }
    
    @objc public func navigationService(_ service: NavigationService, willEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        switch service.simulationMode {
        case .always:
            mapViewController?.statusView.hide(delay: 0, animated: true)
        default:
            return
        }
    }
    
    private func checkTunnelState(at location: CLLocation, along progress: RouteProgress) {
        let inTunnel = navigationService.isInTunnel(at: location, along: progress)
        
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

// MARK: - StyleManagerDelegate

extension NavigationViewController: StyleManagerDelegate {
    @objc(locationForStyleManager:)
    public func location(for styleManager: StyleManager) -> CLLocation? {
        if let location = navigationService.router.location {
            return location
        } else if let firstCoord = route.coordinates?.first {
            return CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
        } else {
            return nil
        }
    }
    
    @objc(styleManager:didApplyStyle:)
    public func styleManager(_ styleManager: StyleManager, didApply style: Style) {
        if mapView?.styleURL != style.mapStyleURL {
            mapView?.style?.transition = MGLTransition(duration: 0.5, delay: 0)
            mapView?.styleURL = style.mapStyleURL
        }
        
        currentStatusBarStyle = style.statusBarStyle ?? .default
        setNeedsStatusBarAppearanceUpdate()
    }
    
    @objc public func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) {
        mapView?.reloadStyle(self)
    }
}

// MARK: - BottomBannerViewControllerDelegate

// Handling cancel action in new Bottom Banner container.
// Code duplicated with RouteMapViewController.mapViewControllerDidDismiss(_:byCanceling:)

extension NavigationViewController: BottomBannerViewControllerDelegate {
    public func didTapCancel(_ sender: Any) {
        if delegate?.navigationViewControllerDidDismiss?(self, byCanceling: true) != nil {
            // The receiver should handle dismissal of the NavigationViewController
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
}

