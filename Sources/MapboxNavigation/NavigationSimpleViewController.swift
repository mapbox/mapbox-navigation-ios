import UIKit
import MapboxCoreNavigation
import MapboxDirections
import MapboxSpeech
import AVFoundation
import UserNotifications
import MobileCoreServices
@_spi(Restricted) import MapboxMaps
import MapboxCoreMaps
import Turf


/**
 `NavigationViewController` is a fully-featured user interface for turn-by-turn navigation. Do not confuse it with the `NavigationController` class in UIKit.
 
 You initialize a navigation view controller based on a predefined `RouteResponse` and `NavigationOptions`. As the user progresses along the route, the navigation view controller shows their surroundings and the route line on a map. Banners above and below the map display key information pertaining to the route. A list of steps and a feedback mechanism are accessible via the navigation view controller.
 
 Route initialization should be configured before view controller's `view` is loaded. Usually, that is automatically done during any of the `init`s, but you may also change this settings via `prepareViewLoading(routeResponse:, routeIndex:, routeOptions:, navigationOptions:)` methods. For example that could be handy while configuring a ViewController for a `UIStoryboardSegue`.
 
 To be informed of significant events and decision points as the user progresses along the route, set the `NavigationService.delegate` property of the `NavigationService` that you provide when creating the navigation options.
 
 `CarPlayNavigationViewController` manages the corresponding user interface on a CarPlay screen.

 - important: Creating an instance of this type with parameters that uses `RouteController` with will start an Active
 Guidance session. The trip session is stopped when the instance is deallocated. For more info read the
 [Pricing Guide](https://docs.mapbox.com/ios/beta/navigation/guides/pricing/).
 */
open class NavigationSimpleViewController: UIViewController, NavigationStatusPresenter, NavigationViewData, BuildingHighlighting {
    
    // MARK: Accessing the View Hierarchy
    
    /**
     The `NavigationMapView` displayed inside the view controller.
     
     - note: Do not change `NavigationMapView.delegate` property; instead, implement the corresponding methods on `NavigationViewControllerDelegate`.
     */
    @objc public var navigationMapView: NavigationMapView? {
        get {
            return navigationView.navigationMapView
        }
        
        set {
            guard let validNavigationMapView = newValue else {
                preconditionFailure("Invalid NavigationMapView instance.")
            }
            
            validNavigationMapView.delegate = self
            validNavigationMapView.navigationCamera.viewportDataSource = NavigationViewportDataSource(validNavigationMapView.mapView,
                                                                                                      viewportDataSourceType: .active)
            
            // Reset any changes that were previously made to `FollowingCameraOptions` to prevent
            // undesired camera behavior in active navigation.
            let navigationViewportDataSource = validNavigationMapView.navigationCamera.viewportDataSource as? NavigationViewportDataSource
            navigationViewportDataSource?.options.followingCameraOptions.centerUpdatesAllowed = true
            navigationViewportDataSource?.options.followingCameraOptions.bearingUpdatesAllowed = true
            navigationViewportDataSource?.options.followingCameraOptions.pitchUpdatesAllowed = true
            navigationViewportDataSource?.options.followingCameraOptions.paddingUpdatesAllowed = true
            navigationViewportDataSource?.options.followingCameraOptions.zoomUpdatesAllowed = true
            navigationViewportDataSource?.options.followingCameraOptions.followsLocationCourse = false
            validNavigationMapView.mapView.ornaments.options.logo.visibility = .hidden
            validNavigationMapView.mapView.ornaments.options.attributionButton.visibility = .hidden
            validNavigationMapView.mapView.ornaments.options.compass.visibility = .hidden
            
            validNavigationMapView.navigationCamera.follow()
            
            navigationView.navigationMapView = validNavigationMapView
        }
    }
    
    func setupNavigationCamera() {
        // By default `NavigationCamera` in active guidance navigation should be set to `NavigationCameraState.following` state.
        if let navigationMapView = navigationMapView {
            navigationMapView.navigationCamera.viewportDataSource = NavigationViewportDataSource(navigationMapView.mapView,
                                                                                                 viewportDataSourceType: .active)
            navigationMapView.navigationCamera.follow()
        }
        
        // In case if `NavigationMapView` instance was injected - do not set initial camera options.
        if let _ = navigationOptions?.navigationMapView {
            return
        }
        
        if let centerCoordinate = navigationService.routeProgress.route.shape?.coordinates.first {
            navigationMapView?.setInitialCamera(centerCoordinate)
        }
    }
    
    var mapTileStore: TileStoreConfiguration.Location? {
        NavigationSettings.shared.tileStoreConfiguration.mapLocation
    }
    
    /**
     `NavigationView`, that is displayed inside the view controller.
     */
    public var navigationView: NavigationView {
        return (view as! NavigationView)
    }
    
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
     A Boolean value that determines whether the map annotates the intersections on current step during active navigation.
     
     If `true`, the map would display an icon of a traffic control device on the intersection,
     such as traffic signal, stop sign, yield sign, or railroad crossing.
     Defaults to `true`.
     */
    public var annotatesIntersectionsAlongRoute: Bool {
        get {
            routeOverlayController?.annotatesIntersections ?? true
        }
        set {
            routeOverlayController?.annotatesIntersections = newValue
            updateIntersectionsAlongRoute()
        }
    }
    
    /**
     `AlternativeRoute`s user might take during this trip to reach the destination using another road.
     
     Array contents are updated automatically duting the trip. Alternative routes may be slower or longer then the main route.
     To get updates, subscribe to `NavigationViewControllerDelegate.navigationViewController(_:didUpdateAlternatives:removedAlternatives:)` or `Notification.Name.routeControllerDidUpdateAlternatives` notification.
     */
    public var continuousAlternatives: [AlternativeRoute] {
        navigationService.router.continuousAlternatives
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
    
    // MARK: Setting Route and Navigation Experience
    
    /**
     The `NavigationOptions` object, which is used for the navigation session.
     */
    public var navigationOptions: NavigationOptions?
    
    /**
     The route options used to get the route.
     */
    public var routeOptions: RouteOptions? {
        navigationService.routeProgress.routeOptions
    }
    
    var _routeOptions: RouteOptions?
    
    // MARK: Traversing the Route
    
    /**
     A `RouteResponse` object constructed by [MapboxDirections](https://docs.mapbox.com/ios/api/directions/) along with route index in it.
     
     In cases where you need to update the route after navigation has started, you can set a new route using
     `Router.updateRoute(with:routeOptions:completion:)` method in `NavigationViewController.navigationService.router` and
     `NavigationViewController` will update its UI accordingly.

     For example:
     - If you update route with the same waypoints as the current one:
     ```swift
     navigationViewController.navigationService.router.updateRoute(with: indexedRouteResponse,
                                                                   routeOptions: nil,
                                                                   completion: nil)
     ```
     - In case you update route with different set of waypoints:
     ```swift
     navigationViewController.navigationService.router.updateRoute(with: indexedRouteResponse,
                                                                   routeOptions: newRouteOptions,
                                                                   completion: nil)
     ```
     */
    public var indexedRouteResponse: IndexedRouteResponse {
        navigationService.indexedRouteResponse
    }
    
    /**
     A `Route` object constructed by [MapboxDirections](https://docs.mapbox.com/ios/api/directions/).
     */
    public var route: Route? {
        navigationService.route
    }
    
    /**
     The currently applied style. Use `StyleManager.applyStyle(type:)` to update this value.
     */
    public private(set) var currentStyleType: StyleType?
    
    /**
     The current style associated with `currentStyleType`. Calling `StyleManager.applyStyle(type:)` will
     result in this value being updated.
     */
    public private(set) var currentStyle: Style?
    
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
    
    var _indexedRouteResponse: IndexedRouteResponse?
    
    /**
     A reference to a MapboxDirections service. Used for rerouting.
     */
    @available(*, deprecated, message: "Use `navigationService.routingProvider` instead. If navigation service was not initialized using `Directions` object - this property is unused and ignored.")
    public var directions: Directions {
        navigationService?.directions ?? NavigationSettings.shared.directions
    }
    
    /**
     The navigation service that coordinates the view controller’s nonvisual components, tracking the user’s location as they proceed along the route.
     */
    private(set) public var navigationService: NavigationService!
    
    var router: Router {
        navigationService.router
    }
    
    func setupNavigationService() {
        guard let indexedRouteResponse = _indexedRouteResponse
        else {
            fatalError("`indexedRouteResponse` and `routeOptions` must be valid to create an instance of `NavigationViewController`.")
        }
        
        if let routeOptions = _routeOptions,
            !(routeOptions is NavigationRouteOptions) {
            Log.info("`Route` was created using `RouteOptions` and not `NavigationRouteOptions`. Although not required, this may lead to a suboptimal navigation experience. Without `NavigationRouteOptions`, it is not guaranteed you will get congestion along the route line, better ETAs and ETA label color dependent on congestion.", category: .navigation)
        }
        
        navigationService = navigationOptions?.navigationService
            ?? MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                       customRoutingProvider: nil,
                                       credentials: NavigationSettings.shared.directions.credentials,
                                       simulating: navigationOptions?.simulationMode)
        
        setupControllers(navigationOptions)
        
        viewObservers.forEach {
            $0?.navigationViewDidLoad(view)
        }
    }
    
    /**
     Determines whether the user location annotation is moved from the raw user location reported by the device to the nearest location along the route.
     
     By default, this property is set to `true`, causing the user location annotation to be snapped to the route.
     */
    public var snapsUserLocationAnnotationToRoute = true
    
    
    private var isTraversingTunnel = false
    
    // MARK: View Lifecycle and Events
    
    /**
     If `true`, `UIApplication.isIdleTimerDisabled` is set to `true` in `viewWillAppear(_:)` and `false` in `viewWillDisappear(_:)`. If your application manages the idle timer itself, set this property to `false`.
     */
    public var shouldManageApplicationIdleTimer = true {
        didSet {
            updateIdleTimerIfNeeded()
        }
    }
    
    private var idleTimerCancellable: IdleTimerManager.Cancellable?
    private var isViewVisible: Bool = false {
        didSet {
            updateIdleTimerIfNeeded()
        }
    }
    
    private func updateIdleTimerIfNeeded() {
        if !isViewVisible {
            idleTimerCancellable = nil
        }
        else if shouldManageApplicationIdleTimer {
            idleTimerCancellable = IdleTimerManager.shared.disableIdleTimer()
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /**
     Initializes a `NavigationViewController` that presents the user interface for following a predefined route based on the given options.

     The route may come directly from the completion handler of the [MapboxDirections](https://docs.mapbox.com/ios/api/directions/) framework’s `Directions.calculate(_:completionHandler:)` method, MapboxCoreNavigation `MapboxRoutingProvider.calculateRoutes(options:completionHandler:)`, or it may be unarchived or created from a JSON object.
     
     - parameter routeResponse: `RouteResponse` object, containing selection of routes to follow.
     - parameter routeIndex: The index of the route within the original `RouteResponse` object.
     - parameter routeOptions: The route options used to get the route.
     - parameter navigationOptions: The navigation options to use for the navigation session.
     */
    @available(*, deprecated, renamed: "init(for:navigationOptions:)")
    required public init(for routeResponse: RouteResponse, routeIndex: Int, routeOptions: RouteOptions, navigationOptions: NavigationOptions? = nil) {
        guard case .route = routeResponse.options else {
            preconditionFailure("NavigationViewController was created with `routeOptions` and a `routeResponse` with `MatchOptions`.")
        }
        
        super.init(nibName: nil, bundle: nil)
        
        _ = prepareViewLoading(routeResponse: routeResponse,
                               routeIndex: routeIndex,
                               routeOptions: routeOptions,
                               navigationOptions: navigationOptions)
    }
    
    /**
     Initializes a `NavigationViewController` that presents the user interface for following a predefined route based on the given options.
     The route may come directly from the completion handler of the [MapboxDirections](https://docs.mapbox.com/ios/api/directions/) framework’s `Directions.calculate(_:completionHandler:)` method, MapboxCoreNavigation `MapboxRoutingProvider.calculateRoutes(options:completionHandler:)`, or it may be unarchived or created from a JSON object.
     
     - parameter routeResponse: `IndexedRouteResponse` object, containing selection of routes to follow.
     - parameter navigationOptions: The navigation options to use for the navigation session.
     */
    required public init(for indexedRouteResponse: IndexedRouteResponse, navigationOptions: NavigationOptions? = nil) {
        super.init(nibName: nil, bundle: nil)
        
        _ = prepareViewLoading(indexedRouteResponse: indexedRouteResponse,
                               navigationOptions: navigationOptions)
    }
    
    /**
     Initializes a `NavigationViewController` that presents the user interface for following a predefined route based on the given options.
     The route may come directly from the completion handler of the [MapboxDirections](https://docs.mapbox.com/ios/api/directions/) framework’s `Directions.calculateRoutes(matching:completionHandler:)` method, MapboxCoreNavigation `MapboxRoutingProvider.calculateRoutes(options:completionHandler:)`, or it may be unarchived or created from a JSON object.
     
     - parameter mapMatchingResponse: `MapMatchingResponse` object, containing selection of routes to follow.
     - parameter routeIndex: The index of the route within the original `RouteResponse` object.
     - parameter navigationOptions: The navigation options to use for the navigation session.
     */
    required public convenience init(for mapMatchingResponse: MapMatchingResponse, routeIndex: Int, navigationOptions: NavigationOptions? = nil) throws {
        try self.init(for: .init(routeResponse: RouteResponse(matching: mapMatchingResponse,
                                                              options: mapMatchingResponse.options,
                                                              credentials: mapMatchingResponse.credentials),
                                 routeIndex: routeIndex),
                      navigationOptions: navigationOptions)
    }
    
    /**
     Initializes a `NavigationViewController` with the given route and navigation service.
     
     - parameter navigationService: The navigation service that manages navigation along the route. Route data and options will be extracted from this instance.
     */
    public convenience init(navigationService service: NavigationService) {
        guard case .route = service.indexedRouteResponse.routeResponse.options else {
            preconditionFailure("NavigationViewController(navigationService:) must recieve `navigationService` created with `RouteOptions`.")
        }
        let navigationOptions = NavigationOptions(navigationService: service)
        self.init(for: service.indexedRouteResponse,
                  navigationOptions: navigationOptions)
    }
    
    deinit {
        suspendNotifications()
        navigationService?.stop()
    }
    
    open override func loadView() {
        let frame = parent?.view.bounds ?? UIScreen.main.bounds
        view = NavigationView(delegate: self,
                              frame: frame,
                              tileStoreLocation: mapTileStore,
                              navigationMapView: self.navigationOptions?.navigationMapView)
        
        navigationView.floatingButtons = []
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
        setupNavigationCamera()
        
        observeNotifications(navigationService!)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        viewObservers.forEach {
            $0?.navigationViewWillAppear(animated)
        }
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
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        isViewVisible = true
        viewObservers.forEach {
            $0?.navigationViewDidAppear(animated)
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        viewObservers.forEach {
            $0?.navigationViewWillDisappear(animated)
        }
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        isViewVisible = false
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
    
    /**
     Updates key settings before loading the view.
     
     This method basically re-runs the setup which takes place in `init`. It could be useful if some of the attributes have changed before `NavigationViewController` did load it's view, or if you did not have access to initializing logic. For example, as a part of `UIStoryboardSegue` configuration.
     
     - parameter routeResponse: `RouteResponse` object, containing selection of routes to follow.
     - parameter routeIndex: The index of the route within the original `RouteResponse` object.
     - parameter routeOptions: The route options used to get the route.
     - parameter navigationOptions: The navigation options to use for the navigation session.
     - returns `True` if setup was successful, `False` if `view` is already loaded and settings did not apply.
     */
    @available(*, deprecated, renamed: "prepareViewLoading(indexedRouteResponse:navigationOptions:)")
    public func prepareViewLoading(routeResponse: RouteResponse, routeIndex: Int, routeOptions: RouteOptions, navigationOptions: NavigationOptions? = nil) -> Bool {
        let result = prepareViewLoading(indexedRouteResponse: .init(routeResponse: routeResponse,
                                                                    routeIndex: routeIndex),
                                        navigationOptions: navigationOptions)
        // saving original `routeOptions` to maintain original behavior
        self._routeOptions = routeOptions
        return result
    }
    
    /**
     Updates key settings before loading the view.
     
     This method basically re-runs the setup which takes place in `init`. It could be useful if some of the attributes have changed before `NavigationViewController` did load it's view, or if you did not have access to initializing logic. For example, as a part of `UIStoryboardSegue` configuration.
     
     - parameter indexedRouteResponse: `IndexedRouteResponse` object, containing selection of routes to follow.
     - parameter navigationOptions: The navigation options to use for the navigation session.
     - returns `True` if setup was successful, `False` if `view` is already loaded and settings did not apply.
     */
    public func prepareViewLoading(indexedRouteResponse: IndexedRouteResponse, navigationOptions: NavigationOptions? = nil) -> Bool {
        guard !isViewLoaded else {
            return false
        }
        
        self._indexedRouteResponse = indexedRouteResponse
        if case let .route(routeOptions) = indexedRouteResponse.routeResponse.options {
            self._routeOptions = routeOptions
        }
        self.navigationOptions = navigationOptions
        
        return true
    }
    
    fileprivate func handleCancelAction() {
        dismiss(animated: true, completion: nil)
    }
        
    var containerViewController: UIViewController {
        return self
    }
    
    var cameraController: CameraController?
    var routeOverlayController: NavigationMapView.RouteOverlayController?
    var viewObservers: [NavigationComponentDelegate?] = []
    
    func setupControllers(_ navigationOptions: NavigationOptions?) {
        routeOverlayController = NavigationMapView.RouteOverlayController(self)
        cameraController = CameraController(self)
        
        viewObservers = [
            routeOverlayController,
            cameraController
        ]
        
        subviewInits.append { [weak self] in
            if let predictiveCacheOptions = self?.navigationOptions?.predictiveCacheOptions {
                self?.navigationMapView?.enablePredictiveCaching(options: predictiveCacheOptions)
            }
        }
        
        subviewInits.forEach {
            $0()
        }
        subviewInits.removeAll()
    }
    
    func setUpSimulatedLocationProvider() {
        let simulatedLocationManager = SimulatedLocationManager(routeProgress: navigationService.routeProgress)
        simulatedLocationManager.speedMultiplier = navigationService.simulationSpeedMultiplier
        navigationMapView?.mapView.location.overrideLocationProvider(with: NavigationLocationProvider(locationManager: simulatedLocationManager))
    }
    
    var navigationComponents: [NavigationComponent] {
        var components: [NavigationComponent] = []
        
        if let routeOverlayController = routeOverlayController {
            components.append(routeOverlayController)
        }
        
        if let cameraController = cameraController {
            components.append(cameraController)
        }
        return components
    }
    
    // MARK: Styling the Layout
    
    /**
     Allows to control highlighting of the destination building on arrival. By default destination buildings will not be highlighted.
     */
    public var waypointStyle: WaypointStyle = .annotation
    
    var approachingDestinationThreshold: CLLocationDistance = DefaultApproachingDestinationThresholdDistance
    var passedApproachingDestinationThreshold: Bool = false
    var currentLeg: RouteLeg?
    var buildingWasFound: Bool = false
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .default
        }
    }
    
    func updateIntersectionsAlongRoute() {
        if annotatesIntersectionsAlongRoute {
            navigationMapView?.updateIntersectionSymbolImages(styleType: currentStyleType)
            navigationMapView?.updateIntersectionAnnotations(with: navigationService.routeProgress)
        } else {
            navigationMapView?.removeIntersectionAnnotations()
        }
    }
    
    // MARK: Notifications Observer Methods

    func observeNotifications(_ service: NavigationService) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(progressDidChange(_:)),
                                               name: .routeControllerProgressDidChange,
                                               object: service.router)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(rerouted(_:)),
                                               name: .routeControllerDidReroute,
                                               object: service.router)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(refresh(_:)),
                                               name: .routeControllerDidRefreshRoute,
                                               object: service.router)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(simulationStateDidChange(_:)),
                                               name: .navigationServiceSimulationDidChange,
                                               object: service)
    }

    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerProgressDidChange,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerDidReroute,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .routeControllerDidRefreshRoute,
                                                  object: nil)
        
        NotificationCenter.default.removeObserver(self,
                                                  name: .navigationServiceSimulationDidChange,
                                                  object: nil)
    }
    
    @objc func progressDidChange(_ notification: NSNotification) {
        guard let progress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress,
              let location = notification.userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation,
              let service = navigationOptions?.navigationService,
              let rawLocation = notification.userInfo?[RouteController.NotificationUserInfoKey.rawLocationKey] as? CLLocation else {
            assertionFailure("RouteProgress and CLLocation should be available.")
            return
        }
        
        // Pass the message onto our navigation components.
        for component in navigationComponents {
            component.navigationService(service, didUpdate: progress, with: location, rawLocation: rawLocation)
        }

        // If the user has arrived, don't snap the user puck.
        // In case if user drives beyond the waypoint, we should accurately depict this.
        guard let destination = progress.currentLeg.destination else {
            preconditionFailure("Current leg has no destination")
        }
        let preventRerouting = RouteController.DefaultBehavior.shouldPreventReroutesWhenArrivingAtWaypoint
        let userArrivedAtWaypoint = progress.currentLegProgress.userHasArrivedAtWaypoint && (progress.currentLegProgress.distanceRemaining <= 0)

        let movePuckToCurrentLocation = !(userArrivedAtWaypoint && snapsUserLocationAnnotationToRoute && preventRerouting)
        if movePuckToCurrentLocation {
            navigationMapView?.moveUserLocation(to: location, animated: true)
        }

        attemptToHighlightBuildings(progress, navigationMapView: navigationMapView)
    }

    @objc func rerouted(_ notification: NSNotification) {
        guard let service = navigationOptions?.navigationService else {
            assertionFailure("RouteProgress and CLLocation should be available.")
            return
        }
        
        for component in navigationComponents {
            component.navigationService(service, didRerouteAlong: service.route, at: notification.userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation, proactive: false)
        }
    }

    @objc func refresh(_ notification: NSNotification) {
        guard let routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress,
              let service = navigationOptions?.navigationService else {
            assertionFailure("RouteProgress and CLLocation should be available.")
            return
        }
        
        for component in navigationComponents {
            component.navigationService(service, didRefresh: routeProgress)
        }
    }

    @objc func simulationStateDidChange(_ notification: NSNotification) {
        guard let simulationState = notification.userInfo?[MapboxNavigationService.NotificationUserInfoKey.simulationStateKey] as? SimulationState,
              let progress = navigationOptions?.navigationService?.routeProgress,
              let service = navigationOptions?.navigationService,
              let simulatedSpeedMultiplier = notification.userInfo?[MapboxNavigationService.NotificationUserInfoKey.simulatedSpeedMultiplierKey] as? Double
              else { return }

        switch simulationState {
        case .willBeginSimulation:
            navigationMapView?.storeLocationProviderBeforeSimulation()
            for component in navigationComponents {
                component.navigationService(service, willBeginSimulating: progress, becauseOf: .poorGPS)
            }
        case .didBeginSimulation:
            for component in navigationComponents {
                component.navigationService(service, didBeginSimulating: progress, becauseOf: .poorGPS)
            }
            setUpSimulatedLocationProvider()
        case .willEndSimulation:
            for component in navigationComponents {
                component.navigationService(service, willEndSimulating: progress, becauseOf: .poorGPS)
            }
            navigationMapView?.useStoredLocationProvider()
        case .didEndSimulation:
            for component in navigationComponents {
                component.navigationService(service, didEndSimulating: progress, becauseOf: .poorGPS)
            }
        default:
            break
        }
    }
    
    public func updateMapStyle(_ style: Style) {
        currentStyleType = style.styleType
        currentStyle = style
        if let styleURI = StyleURI(url: style.mapStyleURL),
           navigationMapView?.mapView.mapboxMap.style.uri?.rawValue != style.mapStyleURL.absoluteString {
            navigationMapView?.mapView.mapboxMap.style.uri = styleURI
            navigationMapView?.mapView.mapboxMap.loadStyleURI(styleURI) { [weak self] result in
                switch result {
                case .success(_):
                    // In case if buildings layer present - update its background color.
                    self?.navigationMapView?.updateBuildingsLayerIfPresent()
                case .failure(let error):
                    Log.error("Failed to load \(styleURI) with error: \(error.localizedDescription).",
                              category: .navigationUI)
                }
            }
            updateIntersectionsAlongRoute()
        }
    }
}

// MARK: - NavigationViewDelegate methods

extension NavigationSimpleViewController: NavigationViewDelegate {
    
    func navigationView(_ view: NavigationView, didTap cancelButton: CancelButton) {
        handleCancelAction()
    }
    
    func navigationView(_ navigationView: NavigationView, didReplace navigationMapView: NavigationMapView) {
        cameraController?.navigationViewData.navigationView.navigationMapView = navigationMapView
        
        // `CameraController` is subscribing for a certain changes in `NavigationMapView`.
        // In case if `NavigationMapView` is injected re-subscription should be performed.
        cameraController?.suspendNotifications()
        cameraController?.resumeNotifications()
    }
}

// MARK: CarPlayConnectionObserver methods

extension NavigationSimpleViewController: CarPlayConnectionObserver {
    
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
