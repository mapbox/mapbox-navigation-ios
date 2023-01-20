import UIKit
import CoreLocation
import MapboxDirections
import Turf

/**
 A navigation service coordinates various nonvisual components that track the user as they navigate along a predetermined route. You use `MapboxNavigationService`, which conforms to this protocol, either as part of `NavigationViewController` or by itself as part of a custom user interface. A navigation service calls methods on its `delegate`, which conforms to the `NavigationServiceDelegate` protocol, whenever significant events or decision points occur along the route.
 
 A navigation service controls a `NavigationLocationManager` for determining the user’s location, a `Router` that tracks the user’s progress along the route, a `MapboxRoutingProvider` service for calculating new routes (only used when rerouting), and a `NavigationEventsManager` for sending telemetry events related to navigation or user feedback.
 
 `NavigationViewController` comes with a `MapboxNavigationService` by default. You may override it to customize the `MapboxRoutingProvider`'s source service or simulation mode. After creating the navigation service, pass it into `NavigationOptions(styles:navigationService:voiceController:topBanner:bottomBanner:)`, then pass that object into `NavigationViewController(for:options:)`.
 
 If you use a navigation service by itself, outside of `NavigationViewController`, call `start()` when the user is ready to begin navigating along the route.
 */
public protocol NavigationService: CLLocationManagerDelegate, RouterDataSource, ActiveNavigationEventsManagerDataSource {
    /**
     The location manager for the service. This will be the object responsible for notifying the service of GPS updates.
     */
    var locationManager: NavigationLocationManager { get }
    
    /**
     A reference to a MapboxDirections service. Used for rerouting.
     */
    @available(*, deprecated, message: "Use `customRoutingProvider` instead. If navigation service was not initialized using `Directions` object - this property is unused and ignored.")
    var directions: Directions { get }
    
    /**
     `RoutingProvider`, used to create a route during refreshing or rerouting.
     */
    @available(*, deprecated, message: "Use `customRoutingProvider` instead. Nullable value now corresponds to SDK default behavior.")
    var routingProvider: RoutingProvider { get }
    
    /**
     Custom `RoutingProvider`, used to create a route during refreshing or rerouting.
     */
    var customRoutingProvider: RoutingProvider? { get }
    
    /**
     Credentials data, used to authorize server requests.
     */
    var credentials: Credentials { get }
    
    /**
     The router object that tracks the user’s progress as they travel along a predetermined route.
     */
    var router: Router { get }
    
    /**
     The events manager, responsible for all telemetry.
     */
    var eventsManager: NavigationEventsManager { get }
    
    /**
     The route along which the user is expected to travel.

     If you want to update the route, use `Router.updateRoute(with:routeOptions:completion:)` method from `router`.
     */
    var route: Route { get }
    
    /**
     The `RouteResponse` object containing active route, plus its index in this `RouteResponse`, if applicable.

     If you want to update the route, use `Router.updateRoute(with:routeOptions:completion:)` method from `router`.
     */
    var indexedRouteResponse: IndexedRouteResponse { get }
    
    /**
     The simulation mode of the service.
     */
    var simulationMode: SimulationMode { get set }
    
    /**
     The simulation speed-multiplier. Modify this if you desire accelerated simulation.
     */
    var simulationSpeedMultiplier: Double { get set }
    
    /**
    The Amount of time the service will wait until it begins simulation in a poor GPS scenerio. Defaults to 2.5 seconds.
     */
    var poorGPSPatience: Double { get set }
    
    /**
     The navigation service’s delegate, which is informed of significant events and decision points along the route.
     
     To synchronize your application’s state with the turn-by-turn navigation experience, set this property before starting the navigation session.
     */
    var delegate: NavigationServiceDelegate? { get set }

    /**
     Starts the navigation service.
     */
    func start()
    
    /**
     Stops the navigation service. You may call `start()` after calling `stop()`.
     */
    func stop()
    
    /**
     Ends the navigation session. Used when arriving at destination.
     */
    func endNavigation(feedback: EndOfRouteFeedback?)
    
    /**
     Interrogates the navigationService as to whether or not the passed-in location is in a tunnel.
     */
    func isInTunnel(at location: CLLocation, along progress: RouteProgress) -> Bool 
}

/**
 A concrete implementation of the `NavigationService` protocol.
 
 `NavigationViewController` comes with a `MapboxNavigationService` by default. You may override it to customize the `Directions` service or simulation mode. After creating the navigation service, pass it into `NavigationOptions(styles:navigationService:voiceController:topBanner:bottomBanner:)`, then pass that object into `NavigationViewController(for:options:)`.
 
 If you use a navigation service by itself, outside of `NavigationViewController`, call `start()` when the user is ready to begin navigating along the route.
 */
public class MapboxNavigationService: NSObject, NavigationService {
    typealias DefaultRouter = RouteController

    // MARK: Simulating Traversing
    
    /**
     The default time interval before beginning simulation when the `.onPoorGPS` or `.inTunnels` simulation options are enabled.
     */
    static let defaultPoorGPSPatience: Double = 2.5 //seconds
    
    /**
     The Amount of time the service will wait until it begins simulation in a poor GPS scenerio. Defaults to 2.5 seconds.
     */
    public var poorGPSPatience: Double = defaultPoorGPSPatience {
        didSet {
            poorGPSTimer.countdownInterval = poorGPSPatience.dispatchInterval
        }
    }
    
    /**
     The simulation mode of the service.
     */
    public var simulationMode: SimulationMode {
        didSet {
            switch simulationMode {
            case .always:
                simulate()
            case .onPoorGPS, .inTunnels:
                poorGPSTimer.arm()
            case .never:
                poorGPSTimer.disarm()
                endSimulation(intent: .manual)
            }
        }
    }

    /**
     The simulation speed multiplier. If you desire the simulation to go faster than real-time, increase this value.
     */
    public var simulationSpeedMultiplier: Double {
        get {
            guard simulationMode == .always else { return 1.0 }
            return simulatedLocationSource?.speedMultiplier ?? 1.0
        }
        set {
            guard simulationMode == .always else { return }
            _simulationSpeedMultiplier = newValue
            simulatedLocationSource?.speedMultiplier = newValue
            let simulationState: SimulationState = isSimulating ? .inSimulation : .notInSimulation
            announceSimulationDidChange(simulationState)
        }
    }
    
    var poorGPSTimer: DispatchTimer { _poorGPSTimer! }
    private var _poorGPSTimer: DispatchTimer?
    private var isSimulating: Bool { return simulatedLocationSource != nil }
    private var _simulationSpeedMultiplier: Double = 1.0
    
    private func simulate(intent: SimulationIntent = .manual) {
        guard !isSimulating else {
            announceSimulationDidChange(.inSimulation)
            return
        }
        let progress = router.routeProgress
        delegate?.navigationService(self, willBeginSimulating: progress, becauseOf: intent)
        announceSimulationDidChange(.willBeginSimulation)
        
        simulatedLocationSource = simulatedLocationSourceType.init(routeProgress: progress)
        simulatedLocationSource?.delegate = self
        simulatedLocationSource?.speedMultiplier = _simulationSpeedMultiplier
        simulatedLocationSource?.startUpdatingLocation()
        simulatedLocationSource?.startUpdatingHeading()
        delegate?.navigationService(self, didBeginSimulating: progress, becauseOf: intent)
        announceSimulationDidChange(.didBeginSimulation)
    }
    
    private func endSimulation(intent: SimulationIntent = .manual) {
        guard isSimulating else {
            announceSimulationDidChange(.notInSimulation)
            return
        }
        let progress = router.routeProgress
        delegate?.navigationService(self, willEndSimulating: progress, becauseOf: intent)
        announceSimulationDidChange(.willEndSimulation)
        
        simulatedLocationSource?.stopUpdatingLocation()
        simulatedLocationSource?.stopUpdatingHeading()
        simulatedLocationSource?.delegate = nil
        simulatedLocationSource = nil
        delegate?.navigationService(self, didEndSimulating: progress, becauseOf: intent)
        announceSimulationDidChange(.didEndSimulation)
    }

    private func announceSimulationDidChange(_ simulationState: SimulationState) {
        let userInfo: [NotificationUserInfoKey: Any] = [
            NotificationUserInfoKey.simulationStateKey: simulationState,
            NotificationUserInfoKey.simulatedSpeedMultiplierKey: _simulationSpeedMultiplier
        ]
        NotificationCenter.default.post(name: .navigationServiceSimulationDidChange, object: self, userInfo: userInfo)
    }
    
    private func resetGPSCountdown() {
        //Sanity check: if we're not on this mode, we have no business here.
        guard simulationMode == .onPoorGPS || simulationMode == .inTunnels else { return }
        
        // Immediately end simulation if it is occuring.
        if isSimulating {
            endSimulation(intent: .poorGPS)
        }
        
        // Reset the GPS countdown.
        poorGPSTimer.reset()
    }
    
    // MARK: Starting and Stopping Navigation
    
    /**
     Starts navigation service.
     
     Whenever navigation service starts billing session is resumed. For more info regarding billing,
     read the [Pricing Guide](https://docs.mapbox.com/ios/beta/navigation/guides/pricing/).
     */
    public func start() {
        // Feed the first location to the router if router doesn't have a location yet. See #1790, #3237 for reference.
        if router.location == nil {
            if let currentLocation = locationManager.location {
                router.locationManager?(nativeLocationSource, didUpdateLocations: [
                   currentLocation
                ])
            }
            else if let coordinate = route.shape?.coordinates.first { // fallback to simulated location.
                router.locationManager?(nativeLocationSource, didUpdateLocations: [
                    CLLocation(coordinate: coordinate,
                               altitude: -1,
                               horizontalAccuracy: -1,
                               verticalAccuracy: -1,
                               course: -1,
                               speed: 0,
                               timestamp: Date())
                ])
            }
        }
        
        nativeLocationSource.startUpdatingHeading()
        nativeLocationSource.startUpdatingLocation()
        
        if simulationMode == .always {
            simulate()
        }
        
        eventsManager.sendRouteRetrievalEvent()
        router.delegate = self
        
        // In case if billing session is already running - do nothing.
        if let routeController = router as? RouteController,
           BillingHandler.shared.sessionState(uuid: routeController.sessionUUID) != .running {
            BillingHandler.shared.resumeBillingSession(with: routeController.sessionUUID)
        }
    }
    
    /**
     Stops navigation service. Navigation service can be resumed by calling `start()` after calling
     `stop()`.
     
     Whenever navigation service stops billing session is paused. For more info regarding billing,
     read the [Pricing Guide](https://docs.mapbox.com/ios/beta/navigation/guides/pricing/).
     */
    public func stop() {
        nativeLocationSource.stopUpdatingHeading()
        nativeLocationSource.stopUpdatingLocation()
        
        if [.always, .onPoorGPS, .inTunnels].contains(simulationMode) {
            endSimulation()
        }
        
        poorGPSTimer.disarm()
        router.delegate = nil
        
        // Navigator should also be paused to prevent further location updates. In case if billing
        // session is not running anymore - do nothing.
        if let routeController = router as? RouteController,
           BillingHandler.shared.sessionState(uuid: routeController.sessionUUID) == .running {
            BillingHandler.shared.pauseBillingSession(with: routeController.sessionUUID)
        }
    }
    
    public func endNavigation(feedback: EndOfRouteFeedback? = nil) {
        eventsManager.sendCancelEvent(rating: feedback?.rating, comment: feedback?.comment)
        stop()
    }
    
    /**
     Intializes a new `NavigationService`.
     
     - parameter routeResponse: `RouteResponse` object, containing selection of routes to follow.
     - parameter routeIndex: The index of the route within the original `RouteResponse` object.
     - parameter routeOptions: The route options used to get the route.
     - parameter directions: The Directions object that created `route`. If this argument is omitted, the shared value of `NavigationSettings.directions` will be used.
     - parameter locationSource: An optional override for the default `NaviationLocationManager`.
     - parameter eventsManagerType: An optional events manager type to use while tracking the route.
     - parameter simulationMode: The simulation mode desired.
     - parameter routerType: An optional router type to use for traversing the route.
     */
    @available(*, deprecated, renamed: "init(indexedRouteResponse:customRoutingProvider:credentials:locationSource:eventsManagerType:simulating:routerType:customActivityType:)")
    public convenience init(routeResponse: RouteResponse,
                            routeIndex: Int,
                            routeOptions: RouteOptions,
                            directions: Directions? = nil,
                            locationSource: NavigationLocationManager? = nil,
                            eventsManagerType: NavigationEventsManager.Type? = nil,
                            simulating simulationMode: SimulationMode? = nil,
                            routerType: Router.Type? = nil) {
        self.init(routeResponse: routeResponse,
                  routeIndex: routeIndex,
                  routeOptions: routeOptions,
                  customRoutingProvider: directions ?? Directions.shared,
                  credentials: directions?.credentials ?? NavigationSettings.shared.directions.credentials,
                  locationSource: locationSource,
                  eventsManagerType: eventsManagerType,
                  simulating: simulationMode,
                  routerType: routerType)
    }
        
    /**
     Intializes a new `NavigationService`.
     
     - parameter routeResponse: `RouteResponse` object, containing selection of routes to follow.
     - parameter routeIndex: The index of the route within the original `RouteResponse` object.
     - parameter routeOptions: The route options used to get the route.
     - parameter routingProvider: `RoutingProvider`, used to create a route during refreshing or rerouting.
     - parameter credentials: Credentials to authorize additional data requests throughout the route.
     - parameter locationSource: An optional override for the default `NaviationLocationManager`.
     - parameter eventsManagerType: An optional events manager type to use while tracking the route.
     - parameter simulationMode: The simulation mode desired.
     - parameter routerType: An optional router type to use for traversing the route.
     */
    @available(*, deprecated, renamed: "init(indexedRouteResponse:customRoutingProvider:credentials:locationSource:eventsManagerType:simulating:routerType:customActivityType:)")
    public convenience init(routeResponse: RouteResponse,
                            routeIndex: Int,
                            routeOptions: RouteOptions,
                            routingProvider: RoutingProvider,
                            credentials: Credentials,
                            locationSource: NavigationLocationManager? = nil,
                            eventsManagerType: NavigationEventsManager.Type? = nil,
                            simulating simulationMode: SimulationMode? = nil,
                            routerType: Router.Type? = nil) {
        self.init(routeResponse: routeResponse,
                  routeIndex: routeIndex,
                  routeOptions: routeOptions,
                  customRoutingProvider: routingProvider,
                  credentials: credentials,
                  locationSource: locationSource,
                  eventsManagerType: eventsManagerType,
                  simulating: simulationMode,
                  routerType: routerType)
    }
    /**
     Intializes a new `NavigationService`.
     
     - parameter routeResponse: `RouteResponse` object, containing selection of routes to follow.
     - parameter routeIndex: The index of the route within the original `RouteResponse` object.
     - parameter routeOptions: The route options used to get the route.
     - parameter customRoutingProvider: Custom `RoutingProvider`, used to create a route during refreshing or rerouting.
     - parameter credentials: Credentials to authorize additional data requests throughout the route.
     - parameter locationSource: An optional override for the default `NaviationLocationManager`.
     - parameter eventsManagerType: An optional events manager type to use while tracking the route.
     - parameter simulationMode: The simulation mode desired.
     - parameter routerType: An optional router type to use for traversing the route.
     - parameter customActivityType: Custom `CLActivityType` to be used for location updates. If not specified, SDK will pick it automatically for current navigation profile.
     */
    @available(*, deprecated, renamed: "init(indexedRouteResponse:customRoutingProvider:credentials:locationSource:eventsManagerType:simulating:routerType:customActivityType:)")
    required public convenience init(routeResponse: RouteResponse,
                         routeIndex: Int,
                         routeOptions: RouteOptions,
                         customRoutingProvider: RoutingProvider? = nil,
                         credentials: Credentials,
                         locationSource: NavigationLocationManager? = nil,
                         eventsManagerType: NavigationEventsManager.Type? = nil,
                         simulating simulationMode: SimulationMode? = nil,
                         routerType: Router.Type? = nil,
                         customActivityType: CLActivityType? = nil) {
        self.init(indexedRouteResponse: .init(routeResponse: routeResponse,
                                              routeIndex: routeIndex),
                  customRoutingProvider: customRoutingProvider,
                  credentials: credentials,
                  locationSource: locationSource,
                  eventsManagerType: eventsManagerType,
                  simulating: simulationMode,
                  routerType: routerType,
                  customActivityType: customActivityType)
    }
    
    /**
     Intializes a new `NavigationService`.
     
     - parameter indexedRouteResponse: `IndexedRouteResponse` object, containing selection of routes to follow.
     - parameter customRoutingProvider: Custom `RoutingProvider`, used to create a route during refreshing or rerouting.
     - parameter credentials: Credentials to authorize additional data requests throughout the route.
     - parameter locationSource: An optional override for the default `NaviationLocationManager`.
     - parameter eventsManagerType: An optional events manager type to use while tracking the route.
     - parameter simulationMode: The simulation mode desired.
     - parameter routerType: An optional router type to use for traversing the route.
     */
    required public init(indexedRouteResponse: IndexedRouteResponse,
                         customRoutingProvider: RoutingProvider? = nil,
                         credentials: Credentials,
                         locationSource: NavigationLocationManager? = nil,
                         eventsManagerType: NavigationEventsManager.Type? = nil,
                         simulating simulationMode: SimulationMode? = nil,
                         routerType: Router.Type? = nil,
                         customActivityType: CLActivityType? = nil) {
        nativeLocationSource = locationSource ?? NavigationLocationManager()
        self.credentials = credentials
        self.simulationMode = simulationMode ?? .inTunnels
        self.simulatedLocationSourceType = SimulatedLocationManager.self
        super.init()

        _poorGPSTimer = DispatchTimer(countdown: poorGPSPatience.dispatchInterval)  { [weak self] in
            guard let self = self,
                  self.simulationMode == .onPoorGPS ||
                    (self.simulationMode == .inTunnels && self.isInTunnel(at: self.router.location!, along: self.routeProgress)) else { return }
            self.simulate(intent: .poorGPS)
        }
        
        commonInit(routerType: routerType,
                   indexedRouteResponse: indexedRouteResponse,
                   customRoutingProvider: customRoutingProvider,
                   eventsManagerType: eventsManagerType,
                   customActivityType: customActivityType)
    }

    private func commonInit(routerType: Router.Type?,
                            indexedRouteResponse: IndexedRouteResponse,
                            customRoutingProvider: RoutingProvider?,
                            eventsManagerType: NavigationEventsManager.Type?,
                            customActivityType: CLActivityType?) {
        resumeNotifications()

        let routerType = routerType ?? DefaultRouter.self
        _router = routerType.init(indexedRouteResponse: indexedRouteResponse,
                                  customRoutingProvider: customRoutingProvider,
                                  dataSource: self)
        let options = indexedRouteResponse.validatedRouteOptions
        NavigationSettings.shared.distanceUnit = .init(options.distanceMeasurementSystem)

        let eventType = eventsManagerType ?? NavigationEventsManager.self
        _eventsManager = eventType.init(activeNavigationDataSource: self,
                                        accessToken: self.credentials.accessToken)
        locationManager.activityType = customActivityType ?? options.activityType
        bootstrapEvents()
        
        router.delegate = self
        nativeLocationSource.delegate = self
        
        Bundle.checkForNavigationSDKUpdates()
        checkForLocationUsageDescription()
    }
    
    /**
     Intializes a new `NavigationService` for replaying a session from provided `History`.
     
     - parameter history: `History` object, containing initial route and location trace to be replayed.
     - parameter customHistoryEventsListener: Custom `ReplayManagerHistoryEventsListener` which will be used to handle replay events. Default value (`nil`)  will also loop route assignment events to update the `Router`.
     - parameter customRoutingProvider: Custom `RoutingProvider`, used to create a route during refreshing or rerouting.
     - parameter credentials: Credentials to authorize additional data requests throughout the route.
     - parameter eventsManagerType: An optional events manager type to use while tracking the route.
     - parameter routerType: An optional router type to use for traversing the route.
     - returns `nil` if provided `historyFileDump` does not contain valid initial route.
     */
    public convenience init?(history: History,
                             customHistoryEventsListener: ReplayManagerHistoryEventsListener? = nil,
                             customRoutingProvider: RoutingProvider? = nil,
                             credentials: Credentials,
                             eventsManagerType: NavigationEventsManager.Type? = nil,
                             routerType: Router.Type? = nil,
                             customActivityType: CLActivityType? = nil) {
        guard let routeResponse = history.initialRoute else {
            return nil
        }
        
        let replayLocationManager = ReplayLocationManager(history: history,
                                                          listener: customHistoryEventsListener)
        self.init(indexedRouteResponse: routeResponse,
                  customRoutingProvider: customRoutingProvider,
                  credentials: credentials,
                  locationSource: replayLocationManager,
                  eventsManagerType: eventsManagerType,
                  routerType: routerType,
                  customActivityType: customActivityType)
        
        if customHistoryEventsListener == nil {
            replayLocationManager.eventsListener = self
        }
    }

    init(indexedRouteResponse: IndexedRouteResponse,
         customRoutingProvider: RoutingProvider?,
         credentials: Credentials,
         locationSource: NavigationLocationManager,
         eventsManagerType: NavigationEventsManager.Type?,
         simulating simulationMode: SimulationMode,
         routerType: Router.Type?,
         customActivityType: CLActivityType?,
         simulatedLocationSourceType: SimulatedLocationManager.Type,
         poorGPSTimer: DispatchTimer) {
        self.nativeLocationSource = locationSource
        self.credentials = credentials
        self.simulationMode = simulationMode
        self.simulatedLocationSourceType = simulatedLocationSourceType
        super.init()

        _poorGPSTimer = poorGPSTimer
        commonInit(routerType: routerType,
                   indexedRouteResponse: indexedRouteResponse,
                   customRoutingProvider: customRoutingProvider,
                   eventsManagerType: eventsManagerType,
                   customActivityType: customActivityType)
    }
    
    deinit {
        suspendNotifications()
        eventsManager.withBackupDataSource(active: self, passive: nil) {
            endNavigation()
        }
        nativeLocationSource.delegate = nil
        simulatedLocationSource?.delegate = nil
    }
    
    private func bootstrapEvents() {
        eventsManager.activeNavigationDataSource = self
        eventsManager.resetSession()
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(_:)), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func applicationWillTerminate(_ notification: NSNotification) {
        endNavigation()
    }
    
    // MARK: Managing Location
    
    /**
     The active location manager. Returns the location simulator if we're actively simulating, otherwise it returns the native location manager.
     */
    public var locationManager: NavigationLocationManager {
        return simulatedLocationSource ?? nativeLocationSource
    }
    
    /**
     The native location source. This is a `NavigationLocationManager` by default, but can be overridden with a custom location manager at initalization.
     */
    private var nativeLocationSource: NavigationLocationManager
    
    /**
     The active location simulator. Only used during `SimulationOption.always`, `SimluatedLocationManager.onPoorGPS` and `SimluatedLocationManager.inTunnels`. If there is no simulation active, this property is `nil`.
     */
    private var simulatedLocationSource: SimulatedLocationManager?

    private let simulatedLocationSourceType: SimulatedLocationManager.Type
    
    /**
     A reference to a MapboxDirections service. Used for rerouting.
     */
    @available(*, deprecated, message: "Use `routingProvider` instead. If navigation service was not initialized using `Directions` object - this property is unused and ignored.")
    public lazy var directions: Directions = self.routingProvider as? Directions ?? NavigationSettings.shared.directions
    
    /**
     Custom `RoutingProvider`, used to create a route during refreshing or rerouting.
     */
    @available(*, deprecated, message: "Use `customRoutingProvider` instead. This property will be equal to `customRoutingProvider` if that is provided or a `MapboxRoutingProvider` instance otherwise.")
    public var routingProvider: RoutingProvider {
        router.routingProvider
    }
    
    /**
     Custom `RoutingProvider`, used to create a route during refreshing or rerouting.
     
     If set to `nil` - default Mapbox implementation will be used.
     */
    public var customRoutingProvider: RoutingProvider? {
        router.customRoutingProvider
    }
    
    /**
     Credentials data, used to authorize server requests.
     */
    public var credentials: Credentials

    
    // MARK: Managing Route-Related Data
    
    /**
     The `NavigationService` delegate. Wraps `RouterDelegate` messages.
     */
    public weak var delegate: NavigationServiceDelegate?
    
    /**
     The active router. By default, a `RouteController`.
     */
    public var router: Router { _router! }
    
    /**
     The events manager. Sends telemetry back to the Mapbox platform.
     */
    public var eventsManager: NavigationEventsManager { _eventsManager! }
    
    public var route: Route {
        router.route
    }
    
    public var indexedRouteResponse: IndexedRouteResponse {
        router.indexedRouteResponse
    }
    
    private var _router: Router?
    private var _eventsManager: NavigationEventsManager?
    
    /**
     Determines if a location is within a tunnel.
     
     - parameter location: The location to test.
     - parameter progress: the RouteProgress model that contains the route geometry.

     */
    public func isInTunnel(at location: CLLocation, along progress: RouteProgress) -> Bool {
        return TunnelAuthority.isInTunnel(at: location, along: progress)
    }

    public func updateRoute(with indexedRouteResponse: IndexedRouteResponse,
                            routeOptions: RouteOptions?,
                            completion: ((Bool) -> Void)?) {
        router.updateRoute(with: indexedRouteResponse, routeOptions: routeOptions, completion: completion)
    }
}

extension MapboxNavigationService: CLLocationManagerDelegate {
    
    // MARK: Handling LocationManager Output
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        router.locationManager?(manager, didUpdateHeading: newHeading)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //If we're always simulating, make sure this is a simulated update.
        if simulationMode == .always, manager != simulatedLocationSource { return }
        
        //update the events manager with the received locations
        eventsManager.record(locations)
        
        //sanity check: make sure the update actually contains a location
        guard let location = locations.last else { return }
        
        //If this is a good organic update, reset the timer.
        if simulationMode == .onPoorGPS || simulationMode == .inTunnels,
            manager == nativeLocationSource,
            location.isQualified {
            //If the timer is disarmed, arm it. This is a good update.
            if poorGPSTimer.state == .disarmed, location.isQualifiedForStartingRoute {
                poorGPSTimer.arm()
            }
            
            //pass this good update onto the poor GPS timer mechanism.
            resetGPSCountdown()
        }
        
        //Finally, pass the update onto the router.
        router.locationManager?(manager, didUpdateLocations: locations)
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            let info: [NotificationUserInfoKey: Any] = [
                .locationAuthorizationKey: manager.value(forKey: "accuracyAuthorization") ?? 0
            ]
            NotificationCenter.default.post(name: .locationAuthorizationDidChange, object: manager, userInfo: info)
            delegate?.navigationServiceDidChangeAuthorization(self, didChangeAuthorizationFor: manager)
        } else {
            // Fallback on earlier versions
            return
        }
    }
}

extension MapboxNavigationService: RouterDelegate {
    typealias Default = RouteController.DefaultBehavior
    
    //MARK: RouteControllerDelegate Implementation
    
    public func router(_ router: Router, willRerouteFrom location: CLLocation) {
        //save any progress made by the router until now
        eventsManager.enqueueRerouteEvent()
        eventsManager.incrementDistanceTraveled(by: router.routeProgress.distanceTraveled)
        
        //notify our consumer
        delegate?.navigationService(self, willRerouteFrom: location)
    }
    
    public func router(_ router: Router, modifiedOptionsForReroute options: RouteOptions) -> RouteOptions {
        return delegate?.navigationService(self, modifiedOptionsForReroute: options) ?? options
    }
    
    public func router(_ router: Router, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        //notify the events manager that the route has changed
        eventsManager.reportReroute(progress: router.routeProgress, proactive: proactive)
        
        //notify our consumer
        delegate?.navigationService(self, didRerouteAlong: route, at: location, proactive: proactive)
    }
    
    public func router(_ router: Router, didFailToRerouteWith error: Error) {
        delegate?.navigationService(self, didFailToRerouteWith: error)
    }
    
    public func router(_ router: Router, didRefresh routeProgress: RouteProgress) {
        delegate?.navigationService(self, didRefresh: routeProgress)
    }
    
    public func router(_ router: Router, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        //notify the events manager of the progress update
        eventsManager.update(progress: progress)
        
        //pass the update on to consumers
        delegate?.navigationService(self, didUpdate: progress, with: location, rawLocation: rawLocation)
    }
    
    public func router(_ router: Router, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress) {
        delegate?.navigationService(self, didPassVisualInstructionPoint: instruction, routeProgress: routeProgress)
    }
    
    public func router(_ router: Router, didPassSpokenInstructionPoint instruction: SpokenInstruction, routeProgress: RouteProgress) {
        delegate?.navigationService(self, didPassSpokenInstructionPoint: instruction, routeProgress: routeProgress)
    }
    
    public func router(_ router: Router, shouldRerouteFrom location: CLLocation) -> Bool {
        return delegate?.navigationService(self, shouldRerouteFrom: location) ?? Default.shouldRerouteFromLocation
    }
    
    public func router(_ router: Router, shouldDiscard location: CLLocation) -> Bool {
        return delegate?.navigationService(self, shouldDiscard: location) ?? Default.shouldDiscardLocation
    }
    
    public func router(_ router: Router, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance) {
        delegate?.navigationService(self, willArriveAt: waypoint, after: remainingTimeInterval, distance: distance)
    }
    
    public func router(_ router: Router, didArriveAt waypoint: Waypoint) -> Bool {
        //Notify the events manager that we've arrived at a waypoint
        if router.routeProgress.remainingWaypoints.count <= 1 {
            eventsManager.arriveAtDestination()
        } else {
            eventsManager.arriveAtWaypoint()
        }
        
        let shouldAutomaticallyAdvance = delegate?.navigationService(self, didArriveAt: waypoint) ?? Default.didArriveAtWaypoint
        if !shouldAutomaticallyAdvance {
            stop()
        }
        return shouldAutomaticallyAdvance
    }
    
    public func router(_ router: Router, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool {
        return delegate?.navigationService(self, shouldPreventReroutesWhenArrivingAt: waypoint) ?? Default.shouldPreventReroutesWhenArrivingAtWaypoint
    }
    
    public func routerShouldDisableBatteryMonitoring(_ router: Router) -> Bool {
        return delegate?.navigationServiceShouldDisableBatteryMonitoring(self) ?? Default.shouldDisableBatteryMonitoring
    }
    
    public func router(_ router: Router, didUpdateAlternatives updatedAlternatives: [AlternativeRoute], removedAlternatives: [AlternativeRoute]) {
        delegate?.navigationService(self, didUpdateAlternatives: updatedAlternatives, removedAlternatives: removedAlternatives)
    }
    
    public func router(_ router: Router, didFailToUpdateAlternatives error: AlternativeRouteError) {
        delegate?.navigationService(self, didFailToUpdateAlternatives: error)
    }
    
    public func router(_ router: Router, didSwitchToCoincidentOnlineRoute coincideRoute: Route) {
        //update the route progress model of the simulated location manager, if applicable.
        simulatedLocationSource?.route = router.route
        
        delegate?.navigationService(self, didSwitchToCoincidentOnlineRoute: coincideRoute)
    }
    
    public func router(_ router: Router, willTakeAlternativeRoute route: Route, at location: CLLocation?) {
        delegate?.navigationService(self, willTakeAlternativeRoute: route, at: location)
    }
    
    public func router(_ router: Router, didTakeAlternativeRouteAt location: CLLocation?) {
        delegate?.navigationService(self, didTakeAlternativeRouteAt: location)
    }
    
    public func router(_ router: Router, didFailToTakeAlternativeRouteAt location: CLLocation?) {
        delegate?.navigationService(self, didFailToTakeAlternativeRouteAt: location)
    }
}

extension MapboxNavigationService {
    //MARK: ActiveNavigationEventsManagerDataSource Logic
    
    public var routeProgress: RouteProgress {
        return router.routeProgress
    }
    
    public var desiredAccuracy: CLLocationAccuracy {
        return locationManager.desiredAccuracy
    }
}

extension MapboxNavigationService {
    
    //MARK: RouterDataSource Implementation
    
    public var locationManagerType: NavigationLocationManager.Type {
        return type(of: locationManager)
    }
}

extension MapboxNavigationService: ReplayManagerHistoryEventsListener {
    public func replyLocationManager(_ manager: ReplayLocationManager, published event: HistoryEvent) {
        // handling `RouteAssignmentHistoryEvent` to replay route updates from user/reroutes/etc.
        if let setRouteEvent = event as? RouteAssignmentHistoryEvent {
            updateRoute(with: setRouteEvent.routeResponse,
                        routeOptions: nil,
                        completion: nil)
        }
    }
}

private extension Double {
    var dispatchInterval: DispatchTimeInterval {
        let milliseconds = self * 1000.0 //milliseconds per second
        let intMilliseconds = Int(milliseconds)
        return .milliseconds(intMilliseconds)
    }
}

private func checkForLocationUsageDescription() {
    guard let _ = Bundle.main.bundleIdentifier else {
        return
    }
    if Bundle.main.locationWhenInUseUsageDescription == nil && Bundle.main.locationAlwaysAndWhenInUseUsageDescription == nil {
        if UserDefaults.standard.object(forKey: "NSLocationWhenInUseUsageDescription") == nil && UserDefaults.standard.object(forKey: "NSLocationAlwaysAndWhenInUseUsageDescription") == nil {
                    preconditionFailure("This application’s Info.plist file must include a NSLocationWhenInUseUsageDescription. See https://developer.apple.com/documentation/corelocation for more information.")
        }
    }
}
