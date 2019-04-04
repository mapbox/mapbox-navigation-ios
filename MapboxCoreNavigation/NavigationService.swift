import UIKit
import CoreLocation
import MapboxDirections

@objc(MBNavigationSimulationIntent)
public enum SimulationIntent: Int{
    case manual, poorGPS
}


/**
 The simulation mode type. Used for setting the simulation mode of the navigation service.
 */
@objc(MBNavigationSimulationOptions)
public enum SimulationMode: Int {
   
    /**
     A setting of `.onPoorGPS` will enable simulation when we do not recieve a location update after the `poorGPSPatience` threshold has elapsed.
     */
    case onPoorGPS

    /**
     A setting of `.always` will simulate route progress at all times.
     */
    case always

    /**
     A setting of `.never` will never enable the location simulator, regardless of circumstances.
     */
    case never
}

/// :nodoc: Internal "using default interaface" flag. Used for telemetry.
@objc(MBDefaultInterfaceFlag)
public protocol DefaultInterfaceFlag {
    /// :nodoc: Internal "using default interaface" flag. Used for telemetry.
    var usesDefaultUserInterface: Bool { get set }
}

/**
 A `NavigationService` is the entry-point protocol for MapboxCoreNavigation.
    It contains all the dependencies needed by the `MapboxNavigation` UI SDK, as well as dependencies for its child objects.
    `MapboxNavigationService` is the default implementation.
    If you would like to implement your own core-navigation stack, be sure to conform to this protocol.
 */
@objc(MBNavigationService)
public protocol NavigationService: CLLocationManagerDelegate, RouterDataSource, EventsManagerDataSource, DefaultInterfaceFlag {
    /**
     The location manager for the service. This will be the object responsible for notifying the service of GPS updates.
     */
    var locationManager: NavigationLocationManager { get }
    
    /**
     A reference to a MapboxDirections service. Used for rerouting.
     */
    var directions: Directions { get }
    
    /**
     The active router, responsible for all route-following.
     */
    var router: Router! { get }
    
    /**
     The events manager, responsible for all telemetry.
     */
    var eventsManager: NavigationEventsManager! { get }
    
    /**
     The route along which the user is expected to travel.
     */
    var route: Route { get set }
    
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
     The `NavigationService` delegate. Wraps `RouterDelegate` messages.
     */
    weak var delegate: NavigationServiceDelegate? { get set }

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
 A `NavigationService` is the entry-point interface into MapboxCoreNavigation. This service manages a `locationManager` (which feeds it location updates), a `Directions` service (for rerouting), a `Router` (for route-following), a `NavigationEventsManager` (for telemetry), and a simulation engine for use during poor GPS conditions.
 */
@objc(MBNavigationService)
public class MapboxNavigationService: NSObject, NavigationService, DefaultInterfaceFlag {
    
    typealias DefaultRouter = RouteController
    
    /**
     The default time interval before beginning simulation when the `.onPoorGPS` simulation option is enabled.
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
     The active location manager. Returns the location simulator if we're actively simulating, otherwise it returns the native location manager.
    */
    public var locationManager: NavigationLocationManager {
        return simulatedLocationSource ?? nativeLocationSource
    }
    
    /**
     A reference to a MapboxDirections service. Used for rerouting.
     */
    public var directions: Directions
    
    /**
     The active router. By default, a `PortableRouteController`.
    */
    public var router: Router!
    
    /**
     The events manager. Sends telemetry back to the Mapbox platform.
    */
    public var eventsManager: NavigationEventsManager!
    
    /**
     The `NavigationService` delegate. Wraps `RouterDelegate` messages.
     */
    public weak var delegate: NavigationServiceDelegate?
    
    /**
     The native location source. This is a `NavigationLocationManager` by default, but can be overridden with a custom location manager at initalization.
    */
    private var nativeLocationSource: NavigationLocationManager
    
    /**
     The active location simulator. Only used during `SimulationOption.always` and `SimluatedLocationManager.onPoorGPS`. If there is no simulation active, this property is `nil`.
    */
    private var simulatedLocationSource: SimulatedLocationManager?

    /**
     The simulation mode of the service.
     */
    public var simulationMode: SimulationMode {
        didSet {
            switch simulationMode {
            case .always:
                simulate()
            case .onPoorGPS:
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
        }
    }
    
    var poorGPSTimer: DispatchTimer!
    private var isSimulating: Bool { return simulatedLocationSource != nil }
    private var _simulationSpeedMultiplier: Double = 1.0
    
    /// :nodoc: Internal Telemetry flag.
    public var usesDefaultUserInterface: Bool {
        get {
            return eventsManager.usesDefaultUserInterface
        }
        set {
            eventsManager.usesDefaultUserInterface = newValue
        }
    }
    
    /**
     Intializes a new `NavigationService`. Useful convienence initalizer for OBJ-C users, for when you just want to set up a service without customizing anything.
     
     - parameter route: The route to follow.
     */
    @objc convenience init(route: Route) {
        self.init(route: route, directions: nil, locationSource: nil, eventsManagerType: nil)
    }
    /**
     Intializes a new `NavigationService`.
     
     - parameter route: The route to follow.
     - parameter directions: The Directions object that created `route`.
     - parameter locationSource: An optional override for the default `NaviationLocationManager`.
     - parameter eventsManagerType: An optional events manager type to use while tracking the route.
     - parameter simulationMode: The simulation mode desired.
     - parameter routerType: An optional router type to use for traversing the route.
     */
    @objc required public init(route: Route,
                               directions: Directions? = nil,
                               locationSource: NavigationLocationManager? = nil,
                               eventsManagerType: NavigationEventsManager.Type? = nil,
                               simulating simulationMode: SimulationMode = .onPoorGPS,
                               routerType: Router.Type? = nil)
    {
        nativeLocationSource = locationSource ?? NavigationLocationManager()
        self.directions = directions ?? Directions.shared
        self.simulationMode = simulationMode
        super.init()
        resumeNotifications()
        
        poorGPSTimer = DispatchTimer(countdown: poorGPSPatience.dispatchInterval)  { [weak self] in
            guard let mode = self?.simulationMode, mode == .onPoorGPS else { return }
            self?.simulate(intent: .poorGPS)
        }
        
        let routerType = routerType ?? DefaultRouter.self
        router = routerType.init(along: route, directions: self.directions, dataSource: self)
        
        let eventType = eventsManagerType ?? NavigationEventsManager.self
        eventsManager = eventType.init(dataSource: self, accessToken: route.accessToken)
        locationManager.activityType = route.routeOptions.activityType
        bootstrapEvents()
        
        router.delegate = self
        nativeLocationSource.delegate = self
        
        checkForUpdates()
        checkForLocationUsageDescription()
    }
    
    deinit {
        suspendNotifications()
        endNavigation()
        nativeLocationSource.delegate = nil
        simulatedLocationSource?.delegate = nil
    }
    
    /**
     Determines if a location is within a tunnel.
     
     - parameter location: The location to test.
     - parameter progress: the RouteProgress model that contains the route geometry.

     */
    public func isInTunnel(at location: CLLocation, along progress: RouteProgress) -> Bool {
        return TunnelAuthority.isInTunnel(at: location, along: progress)
    }

    
    private func simulate(intent: SimulationIntent = .manual) {
        guard !isSimulating else { return }
        let progress = router.routeProgress
        delegate?.navigationService?(self, willBeginSimulating: progress, becauseOf: intent)
        simulatedLocationSource = SimulatedLocationManager(routeProgress: progress)
        simulatedLocationSource?.delegate = self
        simulatedLocationSource?.speedMultiplier = _simulationSpeedMultiplier
        simulatedLocationSource?.startUpdatingLocation()
        simulatedLocationSource?.startUpdatingHeading()
        delegate?.navigationService?(self, didBeginSimulating: progress, becauseOf: intent)
    }
    
    private func endSimulation(intent: SimulationIntent = .manual) {
        guard isSimulating else { return }
        let progress = router.routeProgress
        delegate?.navigationService?(self, willEndSimulating: progress, becauseOf: intent)
        simulatedLocationSource?.stopUpdatingLocation()
        simulatedLocationSource?.stopUpdatingHeading()
        simulatedLocationSource?.delegate = nil
        simulatedLocationSource = nil
        delegate?.navigationService?(self, didEndSimulating: progress, becauseOf: intent)
    }
    
    public var route: Route {
        get {
            return router.route
        }
        set {
            router.route = newValue
        }
    }
    
    public func start() {
        // Jump to the first coordinate on the route if the location source does
        // not yet have a fixed location.
        if router.location == nil,
            let coordinate = route.coordinates?.first {
            let location = CLLocation(coordinate: coordinate, altitude: -1, horizontalAccuracy: -1, verticalAccuracy: -1, course: -1, speed: 0, timestamp: Date())
            router.locationManager?(nativeLocationSource, didUpdateLocations: [location])
        }
        
        nativeLocationSource.startUpdatingHeading()
        nativeLocationSource.startUpdatingLocation()
        
        if simulationMode == .always {
            simulate()
        }
        
        eventsManager.sendRouteRetrievalEvent()
    }
    
    public func stop() {
        nativeLocationSource.stopUpdatingHeading()
        nativeLocationSource.stopUpdatingLocation()
        
        if [.always, .onPoorGPS].contains(simulationMode) {
            endSimulation()
        }
        
        poorGPSTimer.disarm()
    }
    
    public func endNavigation(feedback: EndOfRouteFeedback? = nil) {
        eventsManager.sendCancelEvent(rating: feedback?.rating, comment: feedback?.comment)
        stop()
    }

    private func bootstrapEvents() {
        eventsManager.dataSource = self
        eventsManager.resetSession()
    }

    private func resetGPSCountdown() {
        //Sanity check: if we're not on this mode, we have no business here.
        guard simulationMode == .onPoorGPS else { return }
        
        // Immediately end simulation if it is occuring.
        if isSimulating {
            endSimulation(intent: .poorGPS)
        }
        
        // Reset the GPS countdown.
        poorGPSTimer.reset()
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
}

extension MapboxNavigationService: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        router.locationManager?(manager, didUpdateHeading: newHeading)
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        //If we're always simulating, make sure this is a simulated update.
        if simulationMode == .always, manager != simulatedLocationSource { return }
        
        //update the events manager with the received locations
        eventsManager.record(locations: locations)
        
        //sanity check: make sure the update actually contains a location
        guard let location = locations.last else { return }
        
        //If this is a good organic update, reset the timer.
        if simulationMode == .onPoorGPS,
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
}

//MARK: - RouteControllerDelegate
extension MapboxNavigationService: RouterDelegate {
    typealias Default = RouteController.DefaultBehavior
    
    public func router(_ router: Router, willRerouteFrom location: CLLocation) {
    
        //save any progress made by the router until now
        eventsManager.enqueueRerouteEvent()
        eventsManager.incrementDistanceTraveled(by: router.routeProgress.distanceTraveled)
        
        //notify our consumer
        delegate?.navigationService?(self, willRerouteFrom: location)
    }
    
    public func router(_ router: Router, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        
        //notify the events manager that the route has changed
        eventsManager.reportReroute(progress: router.routeProgress, proactive: proactive)
        
        //update the route progress model of the simulated location manager, if applicable.
        simulatedLocationSource?.route = router.route
        
        //notify our consumer
        delegate?.navigationService?(self, didRerouteAlong: route, at: location, proactive: proactive)
    }
    
    public func router(_ router: Router, didFailToRerouteWith error: Error) {
        delegate?.navigationService?(self, didFailToRerouteWith: error)
    }
    
    public func router(_ router: Router, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        
        //notify the events manager of the progress update
        eventsManager.update(progress: progress)
        
        //pass the update on to consumers
        delegate?.navigationService?(self, didUpdate: progress, with: location, rawLocation: rawLocation)
    }
    
    public func router(_ router: Router, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress) {
        delegate?.navigationService?(self, didPassVisualInstructionPoint: instruction, routeProgress: routeProgress)
    }
    
    public func router(_ router: Router, didPassSpokenInstructionPoint instruction: SpokenInstruction, routeProgress: RouteProgress) {
        delegate?.navigationService?(self, didPassSpokenInstructionPoint: instruction, routeProgress: routeProgress)
    }
    
    //MARK: Questions
    public func router(_ router: Router, shouldRerouteFrom location: CLLocation) -> Bool {
        return delegate?.navigationService?(self, shouldRerouteFrom: location) ?? Default.shouldRerouteFromLocation
    }
    
    public func router(_ router: Router, shouldDiscard location: CLLocation) -> Bool {
        return delegate?.navigationService?(self, shouldDiscard: location) ?? Default.shouldDiscardLocation
    }
    
    public func router(_ router: Router, willArriveAt waypoint: Waypoint, after remainingTimeInterval: TimeInterval, distance: CLLocationDistance) {
        delegate?.navigationService?(self, willArriveAt: waypoint, after: remainingTimeInterval, distance: distance)
    }
    
    public func router(_ router: Router, didArriveAt waypoint: Waypoint) -> Bool {
        
        //Notify the events manager that we've arrived at a waypoint
        eventsManager.arriveAtWaypoint()
        
        return delegate?.navigationService?(self, didArriveAt: waypoint) ?? Default.didArriveAtWaypoint
    }
    
    public func router(_ router: Router, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool {
        return delegate?.navigationService?(self, shouldPreventReroutesWhenArrivingAt: waypoint) ?? Default.shouldPreventReroutesWhenArrivingAtWaypoint
    }
    
    public func routerShouldDisableBatteryMonitoring(_ router: Router) -> Bool {
        return delegate?.navigationServiceShouldDisableBatteryMonitoring?(self) ?? Default.shouldDisableBatteryMonitoring
    }
}

//MARK: EventsManagerDataSource Logic
extension MapboxNavigationService {
    public var routeProgress: RouteProgress {
        return self.router.routeProgress
    }
    
    public var desiredAccuracy: CLLocationAccuracy {
        return self.locationManager.desiredAccuracy
    }
    
}

//MARK: RouterDataSource
extension MapboxNavigationService {
    public var locationProvider: NavigationLocationManager.Type {
        return type(of: locationManager)
    }
}

fileprivate extension NavigationEventsManager {
    func incrementDistanceTraveled(by distance: CLLocationDistance) {
       sessionState?.totalDistanceCompleted += distance
    }
    
    func arriveAtWaypoint() {
        sessionState?.departureTimestamp = nil
        sessionState?.arrivalTimestamp = nil
    }
    
    func record(locations: [CLLocation]) {
        guard let state = sessionState else { return }
        locations.forEach(state.pastLocations.push(_:))
    }
}

private extension Double {
    var dispatchInterval: DispatchTimeInterval {
        let milliseconds = self * 1000.0 //milliseconds per second
        let intMilliseconds = Int(milliseconds)
        return .milliseconds(intMilliseconds)
    }
}


private func checkForUpdates() {
    #if TARGET_IPHONE_SIMULATOR
    guard (NSClassFromString("XCTestCase") == nil) else { return } // Short-circuit when running unit tests
    guard let version = Bundle(for: RouteController.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") else { return }
    let latestVersion = String(describing: version)
    _ = URLSession.shared.dataTask(with: URL(string: "https://docs.mapbox.com/ios/navigation/latest_version.txt")!, completionHandler: { (data, response, error) in
        if let _ = error { return }
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
        
        guard let data = data, let currentVersion = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines) else { return }
        
        if latestVersion != currentVersion {
            let updateString = NSLocalizedString("UPDATE_AVAILABLE", bundle: .mapboxCoreNavigation, value: "Mapbox Navigation SDK for iOS version %@ is now available.", comment: "Inform developer an update is available")
            print(String.localizedStringWithFormat(updateString, latestVersion), "https://github.com/mapbox/mapbox-navigation-ios/releases/tag/v\(latestVersion)")
        }
    }).resume()
    #endif
}

private func checkForLocationUsageDescription() {
    guard let _ = Bundle.main.bundleIdentifier else {
        return
    }
    if Bundle.main.locationAlwaysUsageDescription == nil && Bundle.main.locationWhenInUseUsageDescription == nil && Bundle.main.locationAlwaysAndWhenInUseUsageDescription == nil {
        preconditionFailure("This application’s Info.plist file must include a NSLocationWhenInUseUsageDescription. See https://developer.apple.com/documentation/corelocation for more information.")
    }
}
