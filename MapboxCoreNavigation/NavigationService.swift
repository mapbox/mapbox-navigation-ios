import Foundation
import CoreLocation
import MapboxDirections

@objc(MBNavigationSimulationIntent)
public enum SimulationIntent: Int{
    case manual, poorGPS
}

@objc(MBNavigationSimulationOptions)
public enum SimulationOption: Int {
    case onPoorGPS, always, never
}


@objc(MBNavigationService)
public protocol NavigationService: CLLocationManagerDelegate, RouterDataSource, EventsManagerDataSource {
    var locationManager: NavigationLocationManager { get }
    var directions: Directions { get }
    var router: Router! { get }
    var eventsManager: EventsManager! { get }
    var route: Route { get set }
    var simulationMode: SimulationOption { get }
    var simulationSpeedMultiplier: Double { get set }
    weak var delegate: NavigationServiceDelegate? { get set }
    
    func start()
    func stop()
    func endNavigation(feedback: EndOfRouteFeedback?)
}

@objc(MBNavigationService)
public class MapboxNavigationService: NSObject, NavigationService {
    
    static let poorGPSPatience: DispatchTimeInterval = .milliseconds(1500) //1.5 seconds
    
    public var locationManager: NavigationLocationManager {
        return simulatedLocationSource ?? nativeLocationSource
    }
    public var directions: Directions
    public var router: Router!
    public var eventsManager: EventsManager!
    public weak var delegate: NavigationServiceDelegate?
    
    private var nativeLocationSource: NavigationLocationManager
    private var simulatedLocationSource: SimulatedLocationManager?
    
    private var poorGPSTimer: CountdownTimer!
    public let simulationMode: SimulationOption
    private var isSimulating: Bool { return simulatedLocationSource != nil }
    
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
    
    private var _simulationSpeedMultiplier: Double = 1.0
    
    @objc convenience init(route: Route) {
        self.init(route: route, directions: nil, locationSource: nil, eventsManagerType: nil)
    }
    
    @objc required public init(route: Route,
                  directions: Directions? = nil,
                  locationSource: NavigationLocationManager? = nil,
                  eventsManagerType: EventsManager.Type? = nil,
                  simulating simulationMode: SimulationOption = .onPoorGPS)
    {
        nativeLocationSource = locationSource ?? NavigationLocationManager()
        self.directions = directions ?? Directions.shared
        self.simulationMode = simulationMode
        super.init()
        resumeNotifications()
        poorGPSTimer = CountdownTimer(countdown: MapboxNavigationService.poorGPSPatience, payload: timerPayload)
        router = RouteController(along: route, directions: self.directions, dataSource: self)
        let eventType = eventsManagerType ?? EventsManager.self
        eventsManager = eventType.init(dataSource: self, accessToken: route.accessToken)
        locationManager.activityType = route.routeOptions.activityType
        bootstrapEvents()
        
        router.delegate = self
        nativeLocationSource.delegate = self
        
        if simulationMode == .always {
            simulate()
        }
    }
    
    deinit {
        suspendNotifications()
        endNavigation()
    }
    
    public static func isInTunnel(at location: CLLocation, along progress: RouteProgress) -> Bool {
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
        guard !isSimulating else { return }
        let progress = simulatedLocationSource?.routeProgress ?? router.routeProgress
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
        nativeLocationSource.startUpdatingHeading()
        nativeLocationSource.startUpdatingLocation()
        
        simulatedLocationSource?.startUpdatingHeading()
        simulatedLocationSource?.startUpdatingLocation()

        if simulationMode == .onPoorGPS {
            poorGPSTimer.arm()
        }
        
    }
    
    public func stop() {
        nativeLocationSource.stopUpdatingHeading()
        nativeLocationSource.stopUpdatingLocation()
        
        simulatedLocationSource?.stopUpdatingHeading()
        simulatedLocationSource?.stopUpdatingLocation()
        
        poorGPSTimer.disarm()
    }
    
    public func endNavigation(feedback: EndOfRouteFeedback? = nil) {
        eventsManager.sendCancelEvent(rating: feedback?.rating, comment: feedback?.comment)
        stop()
    }

    private func bootstrapEvents() {
        eventsManager.dataSource = self
        eventsManager.resetSession()
        eventsManager.start()
    }

    private func resetGPSCountdown() {
        guard simulationMode == .onPoorGPS else { return }
        
        // Immediately end simulation if it is occuring.
        if isSimulating {
            endSimulation(intent: .poorGPS)
        }
        
        // Reset the GPS countdown.
        poorGPSTimer.reset()
    }
    
    private func timerPayload() {
        guard simulationMode == .onPoorGPS else { return }
        simulate(intent: .poorGPS)
    }
    
    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(_:)), name: .UIApplicationWillTerminate, object: nil)
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
        
        //update the events manager with the received locations
        eventsManager.record(locations: locations)
        
        guard let location = locations.first else { return }
        
        //If this is a good organic update, reset the timer.
        if simulationMode == .onPoorGPS,
            manager == nativeLocationSource,
            location.isQualified {

            resetGPSCountdown()
            
            if (isSimulating) {
                return //If we're simulating, throw this update away,
                       // which ensures a smooth transition.
            }
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
    
    //MARK: Questions
    public func router(_ router: Router, shouldRerouteFrom location: CLLocation) -> Bool {
        return delegate?.navigationService?(self, shouldRerouteFrom: location) ?? Default.shouldRerouteFromLocation
    }
    
    public func router(_ router: Router, shouldDiscard location: CLLocation) -> Bool {
        return delegate?.navigationService?(self, shouldDiscard: location) ?? Default.shouldDiscardLocation
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
    
    public var location: CLLocation? {
        return self.locationManager.location
    }
    
    public var desiredAccuracy: CLLocationAccuracy {
        return self.locationManager.desiredAccuracy
    }
    
    /// :nodoc: This is used internally when the navigation UI is being used
    public var usesDefaultUserInterface: Bool {
        get {
            return eventsManager.usesDefaultUserInterface
        }
        set {
            eventsManager.usesDefaultUserInterface = newValue
        }
    }
}

//MARK: RouterDataSource
extension MapboxNavigationService {
    public var locationProvider: NavigationLocationManager.Type {
        return type(of: locationManager)
    }
}

fileprivate extension EventsManager {
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
