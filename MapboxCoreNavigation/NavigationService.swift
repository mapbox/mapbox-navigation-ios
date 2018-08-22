import Foundation
import CoreLocation
import MapboxDirections


@objc public enum LocationSource: Int {
    case device, simulated
    
    var isSimulated: Bool { return self == .simulated }
    
    var description: String {
        switch self {
        case .device:
            return String(describing: CLLocationManager.self)
        case .simulated:
            return String(describing: SimulatedLocationManager.self)
        }
    }
}

@objc(MBNavigationSimulationIntent)
public enum SimulationIntent: Int{
    case manual, poorGPS
}

@objc(MBNavigationSimulationOptions)
public enum SimulationOption: Int {
    case onPoorGPS, always, never
}

@objc public protocol NavigationServiceDelegate: RouterDelegate {
    @objc optional func navigationService(_ service: NavigationService, willBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent)
    @objc optional func navigationService(_ service: NavigationService, didBeginSimulating progress: RouteProgress, becauseOf reason: SimulationIntent)
    @objc optional func navigationService(_ service: NavigationService, willEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent)
    @objc optional func navigationService(_ service: NavigationService, didEndSimulating progress: RouteProgress, becauseOf reason: SimulationIntent)
}

@objc(MBNavigationService)
public protocol NavigationService: CLLocationManagerDelegate, RouterDataSource, EventsManagerDataSource {
    var locationManager: NavigationLocationManager { get }
    var router: Router! { get }
    var eventsManager: EventsManager! { get }
    var route: Route { get set }
    weak var delegate: NavigationServiceDelegate? { get set }
    
    func start()
    func stop()
    func endNavigation(feedback: EndOfRouteFeedback?)
}

@objc(MBNavigationService)
public class MapboxNavigationService: NSObject, NavigationService {
    static let poorGPSThreshold: DispatchTimeInterval = .milliseconds(1500) //1.5 seconds
    
    public var locationManager: NavigationLocationManager {
        return simulatedLocationSource ?? nativeLocationSource
    }
    var directions: Directions
    public var router: Router!
    public var eventsManager: EventsManager!
    public weak var delegate: NavigationServiceDelegate?
    
    private var nativeLocationSource: NavigationLocationManager
    private var simulatedLocationSource: SimulatedLocationManager?
    
    private var poorGPSTimer: CountdownTimer!
    private let simulationMode: SimulationOption
    private var isSimulating: Bool { return simulatedLocationSource != nil }
    
    @objc convenience init(route: Route) {
        self.init(route: route, directions: nil, locationSource: nil, eventsManagerType: nil)
    }
    
    @objc required public init(route: Route,
                  directions directionsOverride: Directions? = nil,
                  locationSource locationOverride: NavigationLocationManager? = nil,
                  eventsManagerType: EventsManager.Type? = nil, simulating simulationMode: SimulationOption = .onPoorGPS)
    {
        nativeLocationSource = locationOverride ?? NavigationLocationManager()
        self.directions = directionsOverride ?? Directions.shared
        self.simulationMode = simulationMode
        super.init()
        
        poorGPSTimer = CountdownTimer(countdown: MapboxNavigationService.poorGPSThreshold, payload: timerPayload)
        router = RouteController(along: route, directions: directions, dataSource: self)
        let eventType = eventsManagerType ?? EventsManager.self
        eventsManager = eventType.init(dataSource: self, accessToken: route.accessToken)
        locationManager.activityType = route.routeOptions.activityType
        bootstrapEvents(with: router)
        
        router.delegate = self
        nativeLocationSource.delegate = self
        
        if simulationMode == .always {
            simulate()
        }
    }
    
    public static func isInTunnel(at location: CLLocation, along progress: RouteProgress) -> Bool {
        return TunnelAuthority.isInTunnel(at: location, along: progress)
    }

    
    private func simulate(on potentialProgress: RouteProgress? = nil, intent: SimulationIntent = .manual) {
        guard simulatedLocationSource == nil else { return }
        let progress = potentialProgress ?? router.routeProgress
        delegate?.navigationService?(self, willBeginSimulating: progress, becauseOf: intent)
        simulatedLocationSource = SimulatedLocationManager(routeProgress: progress)
        simulatedLocationSource?.delegate = self
        simulatedLocationSource?.startUpdatingLocation()
        simulatedLocationSource?.startUpdatingHeading()
        delegate?.navigationService?(self, didBeginSimulating: progress, becauseOf: intent)
    }
    
    private func endSimulation(intent: SimulationIntent = .manual) {
        guard simulatedLocationSource != nil else { return }
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

    private func bootstrapEvents(with router: Router) {
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
        if manager == nativeLocationSource, location.isQualified {
            resetGPSCountdown()
            if (simulatedLocationSource != nil) {
                return //If we're simulating, throw this update away,
                       // which ensures a smooth transition.
            }
        }
        
        //Finally, pass the update onto the router.
        router.locationManager?(manager, didUpdateLocations: locations)
    }
}

//MARK: - RouteControllerDelegate
extension MapboxNavigationService: RouteControllerDelegate {
    typealias Default = RouteController.DefaultBehavior
    
    public func routeController(_ routeController: RouteController, willRerouteFrom location: CLLocation) {
        
        //save any progress made by the router until now
        eventsManager.enqueueRerouteEvent()
        eventsManager.incrementDistanceTraveled(by: routeController.routeProgress.distanceTraveled)
        
        //notify our consumer
        delegate?.routeController?(routeController, willRerouteFrom: location)
    }
    
    public func routeController(_ routeController: RouteController, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        
        //notify the events manager that the route has changed
        eventsManager.reportReroute(progress: routeController.routeProgress, proactive: proactive)
        
        //notify our consumer
        delegate?.routeController?(routeController, didRerouteAlong: route, at: location, proactive: proactive)
    }
    
    public func routeController(_ routeController: RouteController, didFailToRerouteWith error: Error) {
        delegate?.routeController?(routeController, didFailToRerouteWith: error)
    }
    
    public func routeController(_ routeController: RouteController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        
        //notify the events manager of the progress update
        eventsManager.update(progress: progress)
        
        //pass the update on to consumers
        delegate?.routeController?(routeController, didUpdate: progress, with: location, rawLocation: rawLocation)
    }
    
    //MARK: Questions
    public func routeController(_ routeController: RouteController, shouldRerouteFrom location: CLLocation) -> Bool {
        return delegate?.routeController?(routeController, shouldRerouteFrom: location) ?? Default.shouldRerouteFromLocation
    }
    
    public func routeController(_ routeController: RouteController, shouldDiscard location: CLLocation) -> Bool {
        return delegate?.routeController?(routeController,shouldDiscard: location) ?? Default.shouldDiscardLocation
    }
    
    public func routeController(_ routeController: RouteController, didArriveAt waypoint: Waypoint) -> Bool {
        
        //Notify the events manager that we've arrived at a waypoint
        eventsManager.arriveAtWaypoint()
        
        return delegate?.routeController?(routeController, didArriveAt: waypoint) ?? Default.didArriveAtWaypoint
    }
    
    public func routeController(_ routeController: RouteController, shouldPreventReroutesWhenArrivingAt waypoint: Waypoint) -> Bool {
        return delegate?.routeController?(routeController, shouldPreventReroutesWhenArrivingAt: waypoint) ?? Default.shouldPreventReroutesWhenArrivingAtWaypoint
    }
    
    public func routeControllerShouldDisableBatteryMonitoring(_ routeController: RouteController) -> Bool {
        return delegate?.routeControllerShouldDisableBatteryMonitoring?(routeController) ?? Default.shouldDisableBatteryMonitoring
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
       sessionState.totalDistanceCompleted += distance
    }
    
    func arriveAtWaypoint() {
        sessionState.departureTimestamp = nil
        sessionState.arrivalTimestamp = nil
    }
    
    func record(locations: [CLLocation]) {
        locations.forEach(sessionState.pastLocations.push(_:))
    }
}
