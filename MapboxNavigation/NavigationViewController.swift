import UIKit
import MapboxCoreNavigation
import MapboxDirections
import MapboxSpeech
import AVFoundation
import Mapbox

/**
 A container view controller is a view controller that behaves as a navigation component; that is, it responds as the user progresses along a route according to the `NavigationServiceDelegate` protocol.
 */
public typealias ContainerViewController = UIViewController & NavigationComponent

/**
 `NavigationViewController` is a fully-featured user interface for turn-by-turn navigation. Do not confuse it with the `NavigationController` class in UIKit.
 
 You initialize a navigation view controller based on a predefined `Route` and `NavigationOptions`. As the user progresses along the route, the navigation view controller shows their surroundings and the route line on a map. Banners above and below the map display key information pertaining to the route. A list of steps and a feedback mechanism are accessible via the navigation view controller.
 
 To be informed of significant events and decision points as the user progresses along the route, set the `NavigationService.delegate` property of the `NavigationService` that you provide when creating the navigation options.
 
 `CarPlayNavigationViewController` manages the corresponding user interface on a CarPlay screen.
 */
@objc(MBNavigationViewController)
open class NavigationViewController: UIViewController, NavigationStatusPresenter {
    
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
     The voice controller that vocalizes spoken instructions along the route at the appropriate times.
     */
    @objc public var voiceController: RouteVoiceController!
    
    /**
     The navigation service that coordinates the view controller’s nonvisual components, tracking the user’s location as they proceed along the route.
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
    
    
    var isConnectedToCarPlay: Bool {
        if #available(iOS 12.0, *) {
            return CarPlayManager.isConnected
        } else {
            return false
        }
    }
    
    var mapViewController: RouteMapViewController?
    
    var topViewController: ContainerViewController?
    
    var bottomViewController: ContainerViewController?
    
    var navigationComponents: [NavigationComponent] {
        var components: [NavigationComponent] = []
        if let mvc = mapViewController {
            components.append(mvc)
        }
        
        if let topViewController = topViewController {
            components.append(topViewController)
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
    
    var currentStatusBarStyle: UIStatusBarStyle = .default
    
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
     Initializes a navigation view controller that presents the user interface for following a predefined route based on the given options.

     The route may come directly from the completion handler of the [MapboxDirections.swift](https://mapbox.github.io/mapbox-navigation-ios/directions/) framework’s `Directions.calculate(_:completionHandler:)` method, or it may be unarchived or created from a JSON object.
     
     - parameter route: The route to navigate along.
     - parameter options: The navigation options to use for the navigation session.
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
        
        styleManager = StyleManager()
        styleManager.delegate = self
        styleManager.styles = options?.styles ?? [DayStyle(), NightStyle()]
        
        let bottomBanner = options?.bottomBanner ?? {
            let viewController = BottomBannerViewController()
            viewController.delegate = self
            return viewController
        }()
        bottomViewController = bottomBanner

        if let customBanner = options?.topBanner {
            topViewController = customBanner
        } else {
            let defaultBanner = TopBannerViewController(nibName: nil, bundle: nil)
            defaultBanner.delegate = self
            defaultBanner.statusView.addTarget(self, action: #selector(NavigationViewController.didChangeSpeed(_:)), for: .valueChanged)
            topViewController = defaultBanner
        }
        
        let mapViewController = RouteMapViewController(navigationService: self.navigationService, delegate: self, topBanner: topViewController!, bottomBanner: bottomBanner)
        
        self.mapViewController = mapViewController
        mapViewController.destination = route.legs.last?.destination
        mapViewController.view.translatesAutoresizingMaskIntoConstraints = false

        
        embed(mapViewController, in: view) { (parent, map) -> [NSLayoutConstraint] in
            return map.view.constraintsForPinning(to: parent.view)
        }
        
        //Manually update the map style since the RMVC missed the "map style change" notification when the style manager was set up.
        if let currentStyle = styleManager.currentStyle {
            updateMapStyle(currentStyle, animated: false)
        }
        
        
        mapViewController.view.pinInSuperview()
        mapViewController.reportButton.isHidden = !showsReportFeedback
        
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
        
        //start the navigation service on presentation.
        self.navigationService.start()
        
        view.clipsToBounds = true

 
        guard let firstInstruction = navigationService.routeProgress.currentLegProgress.currentStepProgress.currentVisualInstruction else {
            return
        }
        navigationService(navigationService, didPassVisualInstructionPoint: firstInstruction, routeProgress: navigationService.routeProgress)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if shouldManageApplicationIdleTimer {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        notifyUserAboutLowVolumeIfNeeded()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        if shouldManageApplicationIdleTimer {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        
    }
    
    func notifyUserAboutLowVolumeIfNeeded() {
        guard !(navigationService.locationManager is SimulatedLocationManager) else { return }
        guard !NavigationSettings.shared.voiceMuted else { return }
        guard AVAudioSession.sharedInstance().outputVolume <= NavigationViewMinimumVolumeForWarning else { return }
        
        let title = String.localizedStringWithFormat(NSLocalizedString("DEVICE_VOLUME_LOW", bundle: .mapboxNavigation, value: "%@ Volume Low", comment: "Format string for indicating the device volume is low; 1 = device model"), UIDevice.current.model)
        showStatus(title: title, spinner: false, duration: 3, animated: true, interactive: false)
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
    
    public func showStatus(title: String, spinner: Bool, duration: TimeInterval, animated: Bool, interactive: Bool) {
        navigationComponents.compactMap({ $0 as? NavigationStatusPresenter }).forEach {
            $0.showStatus(title: title, spinner: spinner, duration: duration, animated: animated, interactive: interactive)
        }
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
    
    @objc func mapViewController(_ mapViewController: RouteMapViewController, didCenterOn location: CLLocation) {
        navigationComponents.compactMap({$0 as? NavigationMapInteractionObserver}).forEach {
            $0.navigationViewController(didCenterOn: location)
        }
    }
}

//MARK: - NavigationServiceDelegate
extension NavigationViewController: NavigationServiceDelegate {
    
    @objc public func navigationService(_ service: NavigationService, shouldRerouteFrom location: CLLocation) -> Bool {
        let defaultBehavior = RouteController.DefaultBehavior.shouldRerouteFromLocation
        let componentsWantReroute = navigationComponents.allSatisfy { $0.navigationService?(service, shouldRerouteFrom: location) ?? defaultBehavior }
        return componentsWantReroute && (delegate?.navigationViewController?(self, shouldRerouteFrom: location) ?? defaultBehavior)
    }
    
    @objc public func navigationService(_ service: NavigationService, willRerouteFrom location: CLLocation) {
        for component in navigationComponents {
            component.navigationService?(service, willRerouteFrom: location)
        }
        
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
        let defaultBehavior = RouteController.DefaultBehavior.shouldDiscardLocation
        let componentsWantToDiscard = navigationComponents.allSatisfy { $0.navigationService?(service, shouldDiscard: location) ?? defaultBehavior }
        return componentsWantToDiscard && (delegate?.navigationViewController?(self, shouldDiscard: location) ?? defaultBehavior)
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
        for component in navigationComponents {
            component.navigationService?(service, didPassSpokenInstructionPoint: instruction, routeProgress: routeProgress)
        }
        
        clearStaleNotifications()
        
        if routeProgress.currentLegProgress.currentStepProgress.durationRemaining <= RouteControllerHighAlertInterval {
            scheduleLocalNotification(about: routeProgress.currentLegProgress.currentStep)
        }
    }
    
    @objc public func navigationService(_ service: NavigationService, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress) {
        for component in navigationComponents {
            component.navigationService?(service, didPassVisualInstructionPoint: instruction, routeProgress: routeProgress)
        }
    }
    
    @objc public func navigationService(_ service: NavigationService, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance) {
        for component in navigationComponents {
            component.navigationService?(service, willArriveAt: waypoint, after: remainingTimeInterval, distance: distance)
        }
        
        delegate?.navigationViewController?(self, willArriveAt: waypoint, after: remainingTimeInterval, distance: distance)
    }
    
    @objc public func navigationService(_ service: NavigationService, didArriveAt waypoint: Waypoint) -> Bool {
        let defaultBehavior = RouteController.DefaultBehavior.didArriveAtWaypoint
        let componentsWantAdvance = navigationComponents.allSatisfy { $0.navigationService?(service, didArriveAt: waypoint) ?? defaultBehavior }
        let advancesToNextLeg = componentsWantAdvance && (delegate?.navigationViewController?(self, didArriveAt: waypoint) ?? defaultBehavior)
        
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
        for component in navigationComponents {
            component.navigationService?(service, willBeginSimulating: progress, becauseOf: reason)
        }
    }
    
    public func navigationService(_ service: NavigationService, didBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        for component in navigationComponents {
            component.navigationService?(service, didBeginSimulating: progress, becauseOf: reason)
        }
    }
    
    @objc public func navigationService(_ service: NavigationService, willEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        for component in navigationComponents {
            component.navigationService?(service, willEndSimulating: progress, becauseOf: reason)
        }
    }
    
    public func navigationService(_ service: NavigationService, didEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        for component in navigationComponents {
            component.navigationService?(service, didEndSimulating: progress, becauseOf: reason)
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
    
    public func navigationService(_ service: NavigationService, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool {
        let defaultBehavior = RouteController.DefaultBehavior.shouldPreventReroutesWhenArrivingAtWaypoint
        return navigationComponents.allSatisfy { $0.navigationService?(service, shouldPreventReroutesWhenArrivingAt: waypoint) ?? defaultBehavior }
    }
    
    public func navigationServiceShouldDisableBatteryMonitoring(_ service: NavigationService) -> Bool {
        let defaultBehavior = RouteController.DefaultBehavior.shouldDisableBatteryMonitoring
        return navigationComponents.allSatisfy { $0.navigationServiceShouldDisableBatteryMonitoring?(service) ?? defaultBehavior }
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
        updateMapStyle(style)
    }
    
    private func updateMapStyle(_ style: Style, animated: Bool = true) {
        if mapView?.styleURL != style.mapStyleURL {
            mapView?.style?.transition = MGLTransition(duration: animated ? 0.5 : 0, delay: 0)
            mapView?.styleURL = style.mapStyleURL
        }
        
        currentStatusBarStyle = style.statusBarStyle ?? .default
        setNeedsStatusBarAppearanceUpdate()
    }
    
    @objc public func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) {
        mapView?.reloadStyle(self)
    }
}
// MARK: - TopBannerViewController
// MARK: Status View Actions
extension NavigationViewController {
    @objc func didChangeSpeed(_ statusView: StatusView) {
        let displayValue = 1+min(Int(9 * statusView.value), 8)
        statusView.showSimulationStatus(speed: displayValue)

        if let locationManager = navigationService.locationManager as? SimulatedLocationManager {
            locationManager.speedMultiplier = Double(displayValue)
        }
    }
}
// MARK: TopBannerViewControllerDelegate
extension NavigationViewController: TopBannerViewControllerDelegate {    
    public func topBanner(_ banner: TopBannerViewController, didSwipeInDirection direction: UISwipeGestureRecognizer.Direction) {
        let progress = navigationService.routeProgress
        let route = progress.route
        
        if direction == .down {
            banner.displayStepsTable()
            
            
            if banner.isDisplayingPreviewInstructions {
                mapViewController?.recenter(self)
            }
            
        } else if direction == .right {
            // prevent swiping when step list is visible
            if banner.isDisplayingSteps {
                return
            }
            
            guard let currentStepIndex = banner.currentPreviewStep?.1 else { return }
            let remainingSteps = progress.remainingSteps
            let prevStepIndex = currentStepIndex.advanced(by: -1)
            guard prevStepIndex >= 0 else { return }
            
            let prevStep = remainingSteps[prevStepIndex]
            preview(step: prevStep, in: banner, remaining: remainingSteps, route: route)
        } else if direction == .left {
            // prevent swiping when step list is visible
            if banner.isDisplayingSteps {
                return
            }
            
            let remainingSteps = navigationService.router.routeProgress.remainingSteps
            let currentStepIndex = banner.currentPreviewStep?.1
            let nextStepIndex = currentStepIndex?.advanced(by: 1) ?? 0
            guard nextStepIndex < remainingSteps.count else { return }
            
            let nextStep = remainingSteps[nextStepIndex]
            preview(step: nextStep, in: banner, remaining: remainingSteps, route: route)
        }
    }
    
    public func preview(step: RouteStep, in banner: TopBannerViewController, remaining: [RouteStep], route: Route, animated: Bool = true) {
        guard let leg = route.leg(containing: step) else { return }
        guard let legIndex = route.legs.index(of: leg) else { return }
        guard let stepIndex = leg.steps.index(of: step) else { return }
        let nextStepIndex = stepIndex + 1
        
        let legProgress = RouteLegProgress(leg: leg, stepIndex: stepIndex)
        guard let upcomingStep = legProgress.upcomingStep else { return }
        
        let previewBanner: CompletionHandler = {
            banner.preview(step: legProgress.currentStep, maneuverStep: upcomingStep, distance: legProgress.currentStep.distance, steps: remaining)
        }
        
        mapViewController?.center(on: upcomingStep, route: route, legIndex: legIndex, stepIndex: nextStepIndex, animated: animated, completion: previewBanner)
        
        
        
    }
    
    public func topBanner(_ banner: TopBannerViewController, didSelect legIndex: Int, stepIndex: Int, cell: StepTableViewCell) {
        let progress = navigationService.routeProgress
        let legProgress = RouteLegProgress(leg: progress.route.legs[legIndex], stepIndex: stepIndex)
        let step = legProgress.currentStep
        self.preview(step: step, in: banner, remaining: progress.remainingSteps, route: progress.route, animated: false)
        banner.dismissStepsTable()
    }
    
    public func topBanner(_ banner: TopBannerViewController, didDisplayStepsController: StepsViewController) {
        mapViewController?.recenter(self)
    }
}

fileprivate extension Route {
    func leg(containing step: RouteStep) -> RouteLeg? {
        return legs.first { $0.steps.contains(step) }
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

// MARK: - CarPlayConnectionObserver

extension NavigationViewController: CarPlayConnectionObserver {
    public func didConnectToCarPlay() {
        navigationComponents.compactMap({$0 as? CarPlayConnectionObserver}).forEach {
            $0.didConnectToCarPlay()
        }
    }
    public func didDisconnectFromCarPlay() {
        navigationComponents.compactMap({$0 as? CarPlayConnectionObserver}).forEach {
            $0.didDisconnectFromCarPlay()
        }
    }
}
