import UIKit
import MapboxCoreNavigation
import MapboxDirections
import MapboxSpeech
import AVFoundation
import UserNotifications
import MobileCoreServices
import MapboxMaps
import MapboxCoreMaps
import Turf

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
open class NavigationViewController: UIViewController, NavigationStatusPresenter, NavigationViewData {
    /**
     A `RouteResponse` object constructed by [MapboxDirections](https://docs.mapbox.com/ios/api/directions/) along with route index in it.
     
     In cases where you need to update the route after navigation has started, you can set a new route using
     `Router.updateRoute(with:routeOptions:)` method in `NavigationViewController.navigationService.router` and
     `NavigationViewController` will update its UI accordingly.

     For example:
     - If you update route with the same waypoints as the current one:
     ```swift
     navigationViewController.navigationService.router.updateRoute(with: indexedRouteResponse, routeOptions: nil)
     ```
     - In case you update route with different set of waypoints:
     ```swift
     navigationViewController.navigationService.router.updateRoute(with: indexedRouteResponse, routeOptions: newRouteOptions)
     ```
     */
    public var indexedRouteResponse: IndexedRouteResponse {
        navigationService.indexedRouteResponse
    }
    
    var _routeIndex: Int?
    var _routeResponse: RouteResponse?
    var _routeOptions: RouteOptions?
    
    /**
     A `Route` object constructed by [MapboxDirections](https://docs.mapbox.com/ios/api/directions/).
     */
    public var route: Route? {
        navigationService.route
    }
    
    /**
     The route options used to get the route.
     */
    public var routeOptions: RouteOptions? {
        navigationService.routeProgress.routeOptions
    }
    
    /**
     Current `RouteResponse` object, as provided by [MapboxDirections](https://docs.mapbox.com/ios/api/directions/).
     */
    public var routeResponse: RouteResponse {
        indexedRouteResponse.routeResponse
    }
    
    /**
     The index of the route within the original `RouteResponse` object.
     */
    public var routeIndex: Int? {
        indexedRouteResponse.routeIndex
    }
    
    /**
     The `NavigationOptions` object, which is used for the navigation session.
     */
    public var navigationOptions: NavigationOptions?
    
    /**
     An instance of `Directions` need for rerouting. See [Mapbox Directions](https://docs.mapbox.com/ios/api/directions/) for further information.
     */
    public var directions: Directions {
        return navigationService.directions
    }
    
    /**
     The receiver’s delegate.
     */
    public weak var delegate: NavigationViewControllerDelegate?
    
    /**
     The voice controller that vocalizes spoken instructions along the route at the appropriate times.
     */
    public var voiceController: RouteVoiceController!
    
    /**
     The `NavigationMapView` displayed inside the view controller.
     
     - note: Do not change `NavigationMapView.delegate` property; instead, implement the corresponding methods on `NavigationViewControllerDelegate`.
     */
    @objc public var navigationMapView: NavigationMapView? {
        get {
            return navigationView.navigationMapView
        }
    }
    
    /**
     Determines whether the user location annotation is moved from the raw user location reported by the device to the nearest location along the route.
     
     By default, this property is set to `true`, causing the user location annotation to be snapped to the route.
     */
    public var snapsUserLocationAnnotationToRoute = true
    
    /**
     Toggles sending of UILocalNotification upon upcoming steps when application is in the background. Defaults to `true`.
     */
    public var sendsNotifications: Bool = true
    
    /**
     Shows a button that allows drivers to report feedback such as accidents, closed roads,  poor instructions, etc. Defaults to `true`.
     */
    public var showsReportFeedback: Bool = true {
        didSet {
            ornamentsController?.reportButton.isHidden = !showsReportFeedback
            showsEndOfRouteFeedback = showsReportFeedback
        }
    }
    
    /**
     Shows End of route Feedback UI when the route controller arrives at the final destination.
     
     Defaults to `true.`
     */
    public var showsEndOfRouteFeedback: Bool {
        get {
            arrivalController?.showsEndOfRoute ?? false
        }
        set {
            arrivalController?.showsEndOfRoute = newValue
        }
    }
    
    /**
     Shows the current speed limit on the map view.
     
     The default value of this property is `true`.
     */
    public var showsSpeedLimits: Bool {
        get {
            ornamentsController?.showsSpeedLimits ?? false
        }
        set {
            ornamentsController?.showsSpeedLimits = newValue
        }
    }
    
    /**
     If true, the map style and UI will automatically be updated given the time of day.
     */
    public var automaticallyAdjustsStyleForTimeOfDay = true {
        didSet {
            styleManager.automaticallyAdjustsStyleForTimeOfDay = automaticallyAdjustsStyleForTimeOfDay
        }
    }

    /**
     If `true`, `UIApplication.isIdleTimerDisabled` is set to `true` in `viewWillAppear(_:)` and `false` in `viewWillDisappear(_:)`. If your application manages the idle timer itself, set this property to `false`.
     */
    public var shouldManageApplicationIdleTimer = true
    
    /**
     Allows to control highlighting of the destination building on arrival. By default destination buildings will not be highlighted.
     */
    public var waypointStyle: WaypointStyle = .annotation
    
    /**
     Controls whether the main route style layer and its casing disappears
     as the user location puck travels over it. Defaults to `false`.
     
     If `true`, the part of the route that has been traversed will be
     rendered with full transparency, to give the illusion of a
     disappearing route. To customize the color that appears on the
     traversed section of a route, override the `traversedRouteColor` property
     for the `NavigationMapView.appearance()`.
     */
    public var routeLineTracksTraversal: Bool {
        get {
            navigationMapView?.routeLineTracksTraversal ?? false
        }
        set {
            navigationMapView?.routeLineTracksTraversal = newValue
            routeOverlayController?.routeLineTracksTraversal = newValue
        }
    }

    /**
     Controls whether or not the FeedbackViewController shows a second level of detail for feedback items.
     
     Defaults to `false`.
     */
    public var detailedFeedbackEnabled: Bool {
        get {
            ornamentsController?.detailedFeedbackEnabled ?? false
        }
        set {
            ornamentsController?.detailedFeedbackEnabled = newValue
        }
    }
        
    var topViewController: ContainerViewController?
    
    var bottomViewController: ContainerViewController?
    
    /**
     The position of floating buttons in a navigation view. The default value is `MapOrnamentPosition.topTrailing`.
     */
    open var floatingButtonsPosition: MapOrnamentPosition? {
        get {
            ornamentsController?.floatingButtonsPosition
        }
        set {
            ornamentsController?.floatingButtonsPosition = newValue
        }
    }
    
    /**
     The floating buttons in an array of UIButton in navigation view. The default floating buttons include the overview, mute and feedback report button. The default type of the floatingButtons is `FloatingButton`, which is declared with `FloatingButton.rounded(image:selectedImage:size:)` to be consistent.
     */
    open var floatingButtons: [UIButton]? {
        get {
            ornamentsController?.floatingButtons
        }
        set {
            ornamentsController?.floatingButtons = newValue
        }
    }
    
    var navigationComponents: [NavigationComponent] {
        var components: [NavigationComponent] = []
        
        if let routeOverlayController = routeOverlayController {
            components.append(routeOverlayController)
        }
        
        if let cameraController = cameraController {
            components.append(cameraController)
        }
        
        if let overlayController = ornamentsController {
            components.append(overlayController)
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
     
     Defaults to `false`.
     */
    public var annotatesSpokenInstructions: Bool {
        get {
            routeOverlayController?.annotatesSpokenInstructions ?? false
        }
        set {
            routeOverlayController?.annotatesSpokenInstructions = newValue
        }
    }
    
    /**
     Controls the styling of NavigationViewController and its components.
     
     The style can be modified programmatically by using `StyleManager.applyStyle(type:)`. 
     */
    public private(set) var styleManager: StyleManager!
    
    var currentStatusBarStyle: UIStatusBarStyle = .default
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return currentStatusBarStyle
        }
    }
    
    /**
     The navigation service that coordinates the view controller’s nonvisual components, tracking the user’s location as they proceed along the route.
     */
    private(set) public var navigationService: NavigationService! {
        didSet {
            arrivalController?.destination = route?.legs.last?.destination
        }
    }
    
    private var traversingTunnel = false
    private var approachingDestinationThreshold: CLLocationDistance = 250.0
    private var passedApproachingDestinationThreshold: Bool = false
    private var currentLeg: RouteLeg?
    private var foundAllBuildings = false
    
    var arrivalController: ArrivalController?
    var cameraController: CameraController?
    var ornamentsController: NavigationMapView.OrnamentsController?
    var routeOverlayController: NavigationMapView.RouteOverlayController?
    var viewObservers: [NavigationComponentDelegate?] = []
    var mapTileStore: TileStoreConfiguration.Location? = .default
    
    // MARK: - NavigationViewData implementation
        
    var navigationView: NavigationView {
        return (view as! NavigationView)
    }
    
    var router: Router {
        navigationService.router
    }
    
    var containerViewController: UIViewController {
        return self
    }
    
    // MARK: - Initialization methods
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /**
     Initializes a `NavigationViewController` that presents the user interface for following a predefined route based on the given options.

     The route may come directly from the completion handler of the [MapboxDirections](https://docs.mapbox.com/ios/api/directions/) framework’s `Directions.calculate(_:completionHandler:)` method, or it may be unarchived or created from a JSON object.
     
     - parameter routeResponse: `RouteResponse` object, containing selection of routes to follow.
     - parameter routeIndex: The index of the route within the original `RouteResponse` object.
     - parameter routeOptions: The route options used to get the route.
     - parameter navigationOptions: The navigation options to use for the navigation session.
     */
    required public init(for routeResponse: RouteResponse, routeIndex: Int, routeOptions: RouteOptions, navigationOptions: NavigationOptions? = nil) {
        if let options = navigationOptions {
            mapTileStore = options.tileStoreConfiguration.mapLocation
        }
        
        
        super.init(nibName: nil, bundle: nil)
        self._routeResponse = routeResponse
        self._routeIndex = routeIndex
        self._routeOptions = routeOptions
        self.navigationOptions = navigationOptions
    }
    
    /**
     Initializes a `NavigationViewController` with the given route and navigation service.
     
     - parameter routeResponse: `RouteResponse` object, containing selection of routes to follow.
     - parameter routeIndex: The index of the route within the original `RouteResponse` object.
     - parameter routeOptions: the options object used to generate the route.
     - parameter navigationService: The navigation service that manages navigation along the route.
     */
    convenience init(routeResponse: RouteResponse, routeIndex: Int, routeOptions: RouteOptions, navigationService service: NavigationService) {
        let navigationOptions = NavigationOptions(navigationService: service)
        self.init(for: routeResponse,
                  routeIndex: routeIndex,
                  routeOptions: routeOptions,
                  navigationOptions: navigationOptions)
    }
    
    deinit {
        navigationService?.stop()
    }
    
    // MARK: - Setting-up methods
    
    func setupNavigationService() {
        guard let routeResponse = _routeResponse,
              let routeIndex = _routeIndex,
              let routeOptions = _routeOptions else {
            fatalError("`route`, `routeIndex` and `routeOptions` must be valid to create an instance of `NavigationViewController`.")
        }
        
        if !(routeOptions is NavigationRouteOptions) {
            print("`Route` was created using `RouteOptions` and not `NavigationRouteOptions`. Although not required, this may lead to a suboptimal navigation experience. Without `NavigationRouteOptions`, it is not guaranteed you will get congestion along the route line, better ETAs and ETA label color dependent on congestion.")
        }
        
        let tileStoreLocation = navigationOptions?.tileStoreConfiguration.navigatorLocation ?? .default
        let defaultNavigationService = MapboxNavigationService(routeResponse: routeResponse,
                                                               routeIndex: routeIndex,
                                                               routeOptions: routeOptions,
                                                               tileStoreLocation: tileStoreLocation)
        navigationService = navigationOptions?.navigationService ?? defaultNavigationService
        navigationService.delegate = self
        
        NavigationSettings.shared.distanceUnit = routeOptions.locale.usesMetric ? .kilometer : .mile
        
        setupControllers(navigationOptions)
        setupStyleManager(navigationOptions)
        
        viewObservers.forEach {
            $0?.navigationViewDidLoad(view)
        }
        
        // Start the navigation service on presentation.
        navigationService.start()
        
        if let firstInstruction = navigationService.routeProgress.currentLegProgress.currentStepProgress.currentVisualInstruction {
            navigationService(navigationService,
                              didPassVisualInstructionPoint: firstInstruction,
                              routeProgress: navigationService.routeProgress)
        }

        navigationMapView?.simulatesLocation = navigationService.locationManager.simulatesLocation
    }
    
    func setupVoiceController() {
        let credentials = navigationService.directions.credentials
        let defaultVoiceController = RouteVoiceController(navigationService: navigationService,
                                                          accessToken: credentials.accessToken,
                                                          host: credentials.host.absoluteString)
        
        voiceController = navigationOptions?.voiceController ?? defaultVoiceController
        
        // Initialize voice controller if it hasn't been overridden.
        // This is optional and lazy so it can be mutated by the developer after init.
        _ = voiceController
    }
    
    func setupStyleManager(_ navigationOptions: NavigationOptions?) {
        styleManager = StyleManager()
        styleManager.delegate = self
        styleManager.styles = navigationOptions?.styles ?? [DayStyle(), NightStyle()]
        
        if let currentStyle = styleManager.currentStyle {
            updateMapStyle(currentStyle)
        }
    }
    
    func setupControllers(_ navigationOptions: NavigationOptions?) {
        arrivalController = ArrivalController(self)
        routeOverlayController = NavigationMapView.RouteOverlayController(self)
        cameraController = CameraController(self)
        ornamentsController = NavigationMapView.OrnamentsController(self, eventsManager: navigationService.eventsManager)
        
        viewObservers = [
            routeOverlayController,
            cameraController,
            ornamentsController,
            arrivalController
        ]
        
        subviewInits.append { [weak self] in
            if let topBanner = self?.addTopBanner(navigationOptions),
               let bottomBanner = self?.addBottomBanner(navigationOptions) {
                self?.ornamentsController?.embedBanners(topBanner: topBanner,
                                                        bottomBanner: bottomBanner)
            }
        }
        
        subviewInits.append { [weak self] in
            if let predictiveCacheOptions = self?.navigationOptions?.predictiveCacheOptions {
                self?.navigationMapView?.enablePredictiveCaching(options: predictiveCacheOptions,
                                                                 tileStoreConfiguration: self?.navigationOptions?.tileStoreConfiguration)
            }
        }
        
        subviewInits.forEach {
            $0()
        }
        subviewInits.removeAll()
        
        arrivalController?.destination = route?.legs.last?.destination
        ornamentsController?.reportButton.isHidden = !showsReportFeedback
    }
    
    func setupNavigationCamera() {
        if let centerCoordinate = navigationService.routeProgress.route.shape?.coordinates.first {
            navigationMapView?.setInitialCamera(centerCoordinate)
        }
        
        // By default `NavigationCamera` in active guidance navigation should be set to `NavigationCameraState.following` state.
        navigationMapView?.navigationCamera.follow()
    }
    
    func addTopBanner(_ navigationOptions: NavigationOptions?) -> ContainerViewController {
        let topBanner = navigationOptions?.topBanner ?? {
            let viewController: TopBannerViewController = .init()
            viewController.delegate = self
            viewController.statusView.addTarget(self, action: #selector(NavigationViewController.didChangeSpeed(_:)), for: .valueChanged)
            
            return viewController
        }()
        
        topViewController = topBanner
        
        return topBanner
    }

    func addBottomBanner(_ navigationOptions: NavigationOptions?) -> ContainerViewController {
        let bottomBanner = navigationOptions?.bottomBanner ?? {
            let viewController: BottomBannerViewController = .init()
            viewController.delegate = self
            
            return viewController
        }()
        
        bottomViewController = bottomBanner
        
        return bottomBanner
    }
    
    fileprivate func handleCancelAction() {
        if delegate?.navigationViewControllerDidDismiss(self, byCanceling: true) != nil {
            // The receiver should handle dismissal of the NavigationViewController
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - UIViewController lifecycle methods
    
    open override func loadView() {
        let frame = parent?.view.bounds ?? UIScreen.main.bounds
        view = NavigationView(delegate: self, frame: frame, tileStoreLocation: mapTileStore, navigationMapView: self.navigationOptions?.navigationMapView)
    }
    
    /**
     Array of initialization hooks to be called at `NavigationViewController.viewDidLoad`.
     
     Once main view is loaded, `NavigationService` starts, and each UI component should be ready to accept navigation events and updates. At the same time, various components require embedding, which triggers main view initialization, which triggers service start... To break this cycle, wrap any custom subview configuration here, to avoid triggering main view initialization before it is required.
     */
    private var subviewInits: [() -> ()] = []
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        view.clipsToBounds = true
        
        setupNavigationService()
        setupVoiceController()
        setupNavigationCamera()
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewObservers.forEach {
            $0?.navigationViewWillAppear(animated)
        }
        
        if shouldManageApplicationIdleTimer {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        
        notifyUserAboutLowVolumeIfNeeded()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewObservers.forEach {
            $0?.navigationViewDidAppear(animated)
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewObservers.forEach {
            $0?.navigationViewWillDisappear(animated)
        }
        
        if shouldManageApplicationIdleTimer {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        viewObservers.forEach {
            $0?.navigationViewDidDisappear(animated)
        }
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        viewObservers.forEach {
            $0?.navigationViewDidLayoutSubviews()
        }
    }
    
    open override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        arrivalController?.updatePreferredContentSize(container.preferredContentSize)
    }
    
    func notifyUserAboutLowVolumeIfNeeded() {
        guard !(navigationService.locationManager is SimulatedLocationManager) else { return }
        guard !NavigationSettings.shared.voiceMuted else { return }
        guard AVAudioSession.sharedInstance().outputVolume <= NavigationViewMinimumVolumeForWarning else { return }
        
        let title = NSLocalizedString("INAUDIBLE_INSTRUCTIONS_CTA", bundle: .mapboxNavigation, value: "Adjust Volume to Hear Instructions", comment: "Label indicating the device volume is too low to hear spoken instructions and needs to be manually increased")
        
        // create low volume notification status and append to array of statuses
        let lowVolumeStatus = StatusView.Status(identifier: "INAUDIBLE_INSTRUCTIONS_CTA", title: title, duration: 3, animated: true, priority: 3)
        show(lowVolumeStatus)
    }
    
    // MARK: - Containerization methods
    
    func embed(_ child: UIViewController, in container: UIView, constrainedBy constraints: ((NavigationViewController, UIViewController) -> [NSLayoutConstraint])?) {
        child.willMove(toParent: self)
        addChild(child)
        container.addSubview(child.view)
        if let childConstraints: [NSLayoutConstraint] = constraints?(self, child) {
            view.addConstraints(childConstraints)
        }
        child.didMove(toParent: self)
    }
    
    // MARK: - Route controller notification handling methods
    
    func scheduleLocalNotification(_ routeProgress: RouteProgress) {
        // Remove any notification about an already completed maneuver, even if there isn’t another notification to replace it with yet.
        let identifier = "com.mapbox.route_progress_instruction"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
        
        guard sendsNotifications else { return }
        guard UIApplication.shared.applicationState == .background else { return }
        let currentLegProgress = routeProgress.currentLegProgress
        if currentLegProgress.currentStepProgress.currentSpokenInstruction !=
            currentLegProgress.currentStep.instructionsSpokenAlongStep?.last {
            return
        }
        guard let instruction = currentLegProgress.currentStep.instructionsDisplayedAlongStep?.last else { return }
        
        let content = UNMutableNotificationContent()
        if let primaryText = instruction.primaryInstruction.text {
            content.title = primaryText
        }
        if let secondaryText = instruction.secondaryInstruction?.text {
            content.subtitle = secondaryText
        }
        
        let imageColor: UIColor
        if #available(iOS 12.0, *) {
            switch traitCollection.userInterfaceStyle {
            case .dark:
                imageColor = .white
            case .light, .unspecified:
                imageColor = .black
            @unknown default:
                imageColor = .black
            }
        } else {
            imageColor = .black
        }
        
        if let image = instruction.primaryInstruction.maneuverImage(side: instruction.drivingSide, color: imageColor, size: CGSize(width: 72, height: 72)) {
            // Bake in any transform required for left turn arrows etc.
            let imageData = UIGraphicsImageRenderer(size: image.size).pngData { (context) in
                image.draw(at: .zero)
            }
            let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent("com.mapbox.navigation.notification-icon.png")
            do {
                try imageData.write(to: temporaryURL)
                let iconAttachment = try UNNotificationAttachment(identifier: "maneuver", url: temporaryURL, options: [UNNotificationAttachmentOptionsTypeHintKey: kUTTypePNG])
                content.attachments = [iconAttachment]
            } catch {
                NSLog("Failed to create UNNotificationAttachment with error: \(error.localizedDescription).")
            }
        }
        
        let notificationRequest = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(notificationRequest, withCompletionHandler: nil)
    }
    
    /**
     Shows a Status for a specified amount of time.
     */
    public func show(_ status: StatusView.Status) {
        navigationComponents.compactMap({ $0 as? NavigationStatusPresenter }).forEach {
            $0.show(status)
        }
    }
    
    /**
     Hides a given Status without hiding the status view.
     */
    public func hide(_ status: StatusView.Status) {
        navigationComponents.compactMap({ $0 as? NavigationStatusPresenter }).forEach {
            $0.hide(status)
        }
    }
}

extension NavigationViewController: NavigationViewDelegate {
    func navigationView(_ view: NavigationView, didTapCancelButton: CancelButton) {
        handleCancelAction()
    }
}

// MARK: - NavigationServiceDelegate methods

extension NavigationViewController: NavigationServiceDelegate {
    
    public func navigationService(_ service: NavigationService, shouldRerouteFrom location: CLLocation) -> Bool {
        let defaultBehavior = RouteController.DefaultBehavior.shouldRerouteFromLocation
        let componentsWantReroute = navigationComponents.allSatisfy { $0.navigationService(service, shouldRerouteFrom: location) }
        return componentsWantReroute && (delegate?.navigationViewController(self, shouldRerouteFrom: location) ?? defaultBehavior)
    }
    
    public func navigationService(_ service: NavigationService, willRerouteFrom location: CLLocation) {
        for component in navigationComponents {
            component.navigationService(service, willRerouteFrom: location)
        }
        
        delegate?.navigationViewController(self, willRerouteFrom: location)
    }
    
    public func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        for component in navigationComponents {
            component.navigationService(service, didRerouteAlong: route, at: location, proactive: proactive)
        }

        delegate?.navigationViewController(self, didRerouteAlong: route)
    }
    
    public func navigationService(_ service: NavigationService, didFailToRerouteWith error: Error) {
        for component in navigationComponents {
            component.navigationService(service, didFailToRerouteWith: error)
        }

        delegate?.navigationViewController(self, didFailToRerouteWith: error)
    }
    
    public func navigationService(_ service: NavigationService, didRefresh routeProgress: RouteProgress) {
        for component in navigationComponents {
            component.navigationService(service, didRefresh: routeProgress)
        }
        
        delegate?.navigationViewController(self, didRefresh: routeProgress)
    }
    
    public func navigationService(_ service: NavigationService, shouldDiscard location: CLLocation) -> Bool {
        let defaultBehavior = RouteController.DefaultBehavior.shouldDiscardLocation
        let componentsWantToDiscard = navigationComponents.allSatisfy { $0.navigationService(service, shouldDiscard: location) }
        return componentsWantToDiscard && (delegate?.navigationViewController(self, shouldDiscard: location) ?? defaultBehavior)
    }
    
    public func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        // Check to see if we're in a tunnel.
        checkTunnelState(at: location, along: progress)
        
        // Pass the message onto our navigation components.
        for component in navigationComponents {
            component.navigationService(service, didUpdate: progress, with: location, rawLocation: rawLocation)
        }

        // If the user has arrived, don't snap the user puck.
        // In case if user drives beyond the waypoint, we should accurately depict this.
        guard let destination = progress.currentLeg.destination else {
            preconditionFailure("Current leg has no destination")
        }
        let shouldPrevent = navigationService.delegate?.navigationService(navigationService, shouldPreventReroutesWhenArrivingAt: destination) ?? RouteController.DefaultBehavior.shouldPreventReroutesWhenArrivingAtWaypoint
        let userHasArrivedAndShouldPreventRerouting = shouldPrevent && !progress.currentLegProgress.userHasArrivedAtWaypoint
        
        if snapsUserLocationAnnotationToRoute, userHasArrivedAndShouldPreventRerouting {
            ornamentsController?.labelCurrentRoad(at: rawLocation, suggestedName: roadName(at: rawLocation), for: location)
            navigationMapView?.moveUserLocation(to: location, animated: true)
        } else  {
            ornamentsController?.labelCurrentRoad(at: rawLocation, suggestedName: roadName(at: rawLocation))
        }
        
        attemptToHighlightBuildings(progress, with: location)
        
        // Finally, pass the message onto the `NavigationViewControllerDelegate`.
        delegate?.navigationViewController(self, didUpdate: progress, with: location, rawLocation: rawLocation)
    }
    
    public func navigationService(_ service: NavigationService, didPassSpokenInstructionPoint instruction: SpokenInstruction, routeProgress: RouteProgress) {
        for component in navigationComponents {
            component.navigationService(service, didPassSpokenInstructionPoint: instruction, routeProgress: routeProgress)
        }
        
        scheduleLocalNotification(routeProgress)
    }
    
    public func navigationService(_ service: NavigationService, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress) {
        for component in navigationComponents {
            component.navigationService(service, didPassVisualInstructionPoint: instruction, routeProgress: routeProgress)
        }
    }
    
    public func navigationService(_ service: NavigationService, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance) {
        for component in navigationComponents {
            component.navigationService(service, willArriveAt: waypoint, after: remainingTimeInterval, distance: distance)
        }
        
        delegate?.navigationViewController(self, willArriveAt: waypoint, after: remainingTimeInterval, distance: distance)
    }
    
    public func navigationService(_ service: NavigationService, didArriveAt waypoint: Waypoint) -> Bool {
        let defaultBehavior = RouteController.DefaultBehavior.didArriveAtWaypoint
        let componentsWantAdvance = navigationComponents.allSatisfy { $0.navigationService(service, didArriveAt: waypoint) }
        let advancesToNextLeg = componentsWantAdvance && (delegate?.navigationViewController(self, didArriveAt: waypoint) ?? defaultBehavior)
        
        arrivalController?.showEndOfRouteIfNeeded(self,
                                                  advancesToNextLeg: advancesToNextLeg,
                                                  onDismiss: { [weak self] in
                                                    self?.navigationService.endNavigation(feedback: $0)
                                                    self?.handleCancelAction()
                                                  })
        return advancesToNextLeg
    }

    public func navigationService(_ service: NavigationService, willBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        for component in navigationComponents {
            component.navigationService(service, willBeginSimulating: progress, becauseOf: reason)
        }
        navigationMapView?.simulatesLocation = true
    }
    
    public func navigationService(_ service: NavigationService, didBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        for component in navigationComponents {
            component.navigationService(service, didBeginSimulating: progress, becauseOf: reason)
        }
        let simulatedLocationProvider = NavigationLocationProvider(locationManager: SimulatedLocationManager(routeProgress: progress))
        navigationMapView?.mapView.location.overrideLocationProvider(with: simulatedLocationProvider)
    }
    
    public func navigationService(_ service: NavigationService, willEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        for component in navigationComponents {
            component.navigationService(service, willEndSimulating: progress, becauseOf: reason)
        }
        navigationMapView?.simulatesLocation = false
    }
    
    public func navigationService(_ service: NavigationService, didEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent) {
        for component in navigationComponents {
            component.navigationService(service, didEndSimulating: progress, becauseOf: reason)
        }
        navigationMapView?.mapView.location.overrideLocationProvider(with: AppleLocationProvider())
        navigationMapView?.mapView.location.locationProvider.startUpdatingHeading()
        navigationMapView?.mapView.location.locationProvider.startUpdatingLocation()
    }
    
    private func checkTunnelState(at location: CLLocation, along progress: RouteProgress) {
        let inTunnel = navigationService.isInTunnel(at: location, along: progress)
        
        // Entering tunnel
        if !traversingTunnel, inTunnel {
            traversingTunnel = true
            styleManager.applyStyle(type: .night)
        }
        
        // Exiting tunnel
        if traversingTunnel, !inTunnel {
            traversingTunnel = false
            styleManager.timeOfDayChanged()
        }
    }
    
    public func navigationService(_ service: NavigationService, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool {
        return navigationComponents.allSatisfy { $0.navigationService(service, shouldPreventReroutesWhenArrivingAt: waypoint) }
    }
    
    public func navigationServiceShouldDisableBatteryMonitoring(_ service: NavigationService) -> Bool {
        return navigationComponents.allSatisfy { $0.navigationServiceShouldDisableBatteryMonitoring(service) }
    }
    
    public func navigationServiceDidChangeAuthorization(_ service: NavigationService, didChangeAuthorizationFor locationManager: CLLocationManager) {
        if #available(iOS 14.0, *), locationManager.accuracyAuthorization == .reducedAccuracy {
            let title = NSLocalizedString("ENABLE_PRECISE_LOCATION", bundle: .mapboxNavigation, value: "Enable precise location to navigate", comment: "Label indicating precise location is off and needs to be turned on to navigate")
            show(StatusView.Status(identifier: "ENABLE_PRECISE_LOCATION",
                                   title: title,
                                   spinner: false,
                                   duration: 20,
                                   animated: true,
                                   interactive: false,
                                   priority: 1))
            navigationMapView?.reducedAccuracyActivatedMode = true
        } else {
            // Fallback on earlier versions
            navigationMapView?.reducedAccuracyActivatedMode = false
            return
        }
    }
    
    // MARK: - Building Extrusion Highlighting methods
    
    private func attemptToHighlightBuildings(_ progress: RouteProgress, with location: CLLocation) {
        // In case if distance was fully covered - do nothing.
        // FIXME: This check prevents issue which leads to highlighting random buildings after arrival to final destination.
        // At the same time this check will prevent building highlighting in case of arrival in overview mode/high altitude.
        if progress.fractionTraveled >= 1.0 { return }
        if waypointStyle == .annotation { return }

        if currentLeg != progress.currentLeg {
            currentLeg = progress.currentLeg
            passedApproachingDestinationThreshold = false
            foundAllBuildings = false
        }
        
        if !passedApproachingDestinationThreshold, progress.currentLegProgress.distanceRemaining < approachingDestinationThreshold {
            passedApproachingDestinationThreshold = true
        }
        
        if !foundAllBuildings, passedApproachingDestinationThreshold,
           let currentLegWaypoint = progress.currentLeg.destination?.targetCoordinate {
            navigationMapView?.highlightBuildings(at: [currentLegWaypoint],
                                                  in3D: waypointStyle == .extrudedBuilding ? true : false,
                                                  completion: { (found) in
                                                    self.foundAllBuildings = found
                                                  })
        }
    }
}

// MARK: - StyleManagerDelegate

extension NavigationViewController: StyleManagerDelegate {
    
    func roadName(at location: CLLocation) -> String? {
        guard let roadName = delegate?.navigationViewController(self, roadNameAt: location) else {
            return nil
        }
        return roadName
    }
    
    public func location(for styleManager: StyleManager) -> CLLocation? {
        if let location = navigationService.router.location {
            return location
        } else if let firstCoord = route?.shape?.coordinates.first {
            return CLLocation(latitude: firstCoord.latitude, longitude: firstCoord.longitude)
        } else {
            return nil
        }
    }
    
    public func styleManager(_ styleManager: StyleManager, didApply style: Style) {
        updateMapStyle(style)
    }
    
    private func updateMapStyle(_ style: Style) {
        if navigationMapView?.mapView.mapboxMap.style.uri?.rawValue != style.mapStyleURL.absoluteString {
            navigationMapView?.mapView.mapboxMap.style.uri = StyleURI(url: style.mapStyleURL)
        }
        
        currentStatusBarStyle = style.statusBarStyle ?? .default
        setNeedsStatusBarAppearanceUpdate()
    }
    
    public func styleManagerDidRefreshAppearance(_ styleManager: StyleManager) {
        guard let mapboxMap = navigationMapView?.mapView.mapboxMap,
              let styleURI = mapboxMap.style.uri else { return }

        mapboxMap.loadStyleURI(styleURI)
    }
}

// MARK: - TopBannerViewController methods

extension NavigationViewController {

    // MARK: StatusView action related methods
    
    @objc func didChangeSpeed(_ statusView: StatusView) {
        let displayValue = 1+min(Int(9 * statusView.value), 8)
        statusView.showSimulationStatus(speed: displayValue)

        navigationService.simulationSpeedMultiplier = Double(displayValue)
    }
}

// MARK: - TopBannerViewControllerDelegate methods

extension NavigationViewController: TopBannerViewControllerDelegate {
    
    public func topBanner(_ banner: TopBannerViewController, didSwipeInDirection direction: UISwipeGestureRecognizer.Direction) {
        let progress = navigationService.routeProgress
        let route = progress.route
        switch direction {
        case .up where banner.isDisplayingSteps:
            banner.dismissStepsTable()
        
        case .down where !banner.isDisplayingSteps:
            banner.displayStepsTable()
            
            if banner.isDisplayingPreviewInstructions {
                cameraController?.recenter(self)
            }
        default:
            break
        }
        
        if !banner.isDisplayingSteps {
            switch (direction, UIApplication.shared.userInterfaceLayoutDirection) {
            case (.right, .leftToRight), (.left, .rightToLeft):
                guard let currentStepIndex = banner.currentPreviewStep?.1 else { return }
                let remainingSteps = progress.remainingSteps
                let prevStepIndex = currentStepIndex.advanced(by: -1)
                guard prevStepIndex >= 0 else { return }
                
                let prevStep = remainingSteps[prevStepIndex]
                preview(step: prevStep, in: banner, remaining: remainingSteps, route: route)
                
            case (.left, .leftToRight), (.right, .rightToLeft):
                let remainingSteps = navigationService.router.routeProgress.remainingSteps
                let currentStepIndex = banner.currentPreviewStep?.1
                let nextStepIndex = currentStepIndex?.advanced(by: 1) ?? 0
                guard nextStepIndex < remainingSteps.count else { return }
                
                let nextStep = remainingSteps[nextStepIndex]
                preview(step: nextStep, in: banner, remaining: remainingSteps, route: route)
            
            default:
                break
            }
        }
    }
    
    public func preview(step: RouteStep,
                        in banner: TopBannerViewController,
                        remaining: [RouteStep],
                        route: Route,
                        animated: Bool = true) {
        guard let leg = route.leg(containing: step),
              let legIndex = route.legs.firstIndex(of: leg),
              let stepIndex = leg.steps.firstIndex(of: step) else { return }

        let legProgress = RouteLegProgress(leg: leg, stepIndex: stepIndex)
        guard let upcomingStep = legProgress.upcomingStep else { return }
        
        let previewBanner: CompletionHandler = {
            banner.preview(step: legProgress.currentStep,
                           maneuverStep: upcomingStep,
                           distance: legProgress.currentStep.distance,
                           steps: remaining)
        }
        
        cameraController?.center(on: upcomingStep,
                                 route: route,
                                 legIndex: legIndex,
                                 stepIndex: stepIndex + 1,
                                 animated: animated,
                                 completion: previewBanner)
        
        banner.preview(step: legProgress.currentStep,
                       maneuverStep: upcomingStep,
                       distance: legProgress.currentStep.distance,
                       steps: remaining)
    }
    
    public func topBanner(_ banner: TopBannerViewController, didSelect legIndex: Int, stepIndex: Int, cell: StepTableViewCell) {
        let progress = navigationService.routeProgress
        let legProgress = RouteLegProgress(leg: progress.route.legs[legIndex], stepIndex: stepIndex)
        let step = legProgress.currentStep
        self.preview(step: step, in: banner, remaining: progress.remainingSteps, route: progress.route)
        banner.dismissStepsTable()
    }
    
    public func topBanner(_ banner: TopBannerViewController, didDisplayStepsController: StepsViewController) {
        cameraController?.recenter(self)
    }
}

// MARK: - BottomBannerViewControllerDelegate methods

extension NavigationViewController: BottomBannerViewControllerDelegate {
    
    // Handle cancel action in new Bottom Banner container.
    public func didTapCancel(_ sender: Any) {
        handleCancelAction()
    }
}

// MARK: - CarPlayConnectionObserver methods

extension NavigationViewController: CarPlayConnectionObserver {
    
    public func didConnectToCarPlay() {
        navigationComponents.compactMap({ $0 as? CarPlayConnectionObserver }).forEach {
            $0.didConnectToCarPlay()
        }
    }
    
    public func didDisconnectFromCarPlay() {
        navigationComponents.compactMap({ $0 as? CarPlayConnectionObserver }).forEach {
            $0.didDisconnectFromCarPlay()
        }
    }
}

// MARK: - NavigationMapViewDelegate methods

extension NavigationViewController: NavigationMapViewDelegate {
    
    public func navigationMapView(_ navigationMapView: NavigationMapView, routeLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
        delegate?.navigationViewController(self, routeLineLayerWithIdentifier: identifier, sourceIdentifier: sourceIdentifier)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView, routeCasingLineLayerWithIdentifier identifier: String, sourceIdentifier: String) -> LineLayer? {
        delegate?.navigationViewController(self, routeCasingLineLayerWithIdentifier: identifier, sourceIdentifier: sourceIdentifier)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView, waypointCircleLayerWithIdentifier identifier: String, sourceIdentifier: String) -> CircleLayer? {
        delegate?.navigationViewController(self, waypointCircleLayerWithIdentifier: identifier, sourceIdentifier: sourceIdentifier)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView, waypointSymbolLayerWithIdentifier identifier: String, sourceIdentifier: String) -> SymbolLayer? {
        delegate?.navigationViewController(self, waypointSymbolLayerWithIdentifier: identifier, sourceIdentifier: sourceIdentifier)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView, shapeFor waypoints: [Waypoint], legIndex: Int) -> FeatureCollection? {
        delegate?.navigationViewController(self, shapeFor: waypoints, legIndex: legIndex)
    }
    
    public func navigationMapView(_ navigationMapView: NavigationMapView, didAdd finalDestinationAnnotation: PointAnnotation, pointAnnotationManager: PointAnnotationManager) {
        delegate?.navigationViewController(self, didAdd: finalDestinationAnnotation, pointAnnotationManager: pointAnnotationManager)
    }
}
