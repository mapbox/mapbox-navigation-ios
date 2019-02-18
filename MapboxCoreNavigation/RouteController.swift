import Foundation
import CoreLocation
import MapboxNavigationNative
import MapboxMobileEvents
import MapboxDirections
import Polyline
import Turf


/**
 A `RouteController` tracks the user’s progress along a route, posting notifications as the user reaches significant points along the route. On every location update, the route controller evaluates the user’s location, determining whether the user remains on the route. If not, the route controller calculates a new route.
 
 `RouteController` is responsible for the core navigation logic whereas
 `NavigationViewController` is responsible for displaying a default drop-in navigation UI.
 */
@objc(MBRouteController)
open class RouteController: NSObject {
    
    public enum DefaultBehavior {
        public static let shouldRerouteFromLocation: Bool = true
        public static let shouldDiscardLocation: Bool = true
        public static let didArriveAtWaypoint: Bool = true
        public static let shouldPreventReroutesWhenArrivingAtWaypoint: Bool = true
        public static let shouldDisableBatteryMonitoring: Bool = true
    }
    
    let navigator = MBNavigator()
    
    public var route: Route {
        get {
            return routeProgress.route
        }
        set {
            routeProgress = RouteProgress(route: newValue)
            updateNavigator()
        }
    }
    
    private var _routeProgress: RouteProgress {
        didSet {
            movementsAwayFromRoute = 0
            updateNavigator()
        }
    }
    
    var movementsAwayFromRoute = 0
    
    var routeTask: URLSessionDataTask?
    
    var lastRerouteLocation: CLLocation?
    
    var didFindFasterRoute = false
    
    var isRerouting = false
    
    var userSnapToStepDistanceFromManeuver: CLLocationDistance?
    
    var previousArrivalWaypoint: Waypoint?
    
    var isFirstLocation: Bool = true
    
    var cumulativeDistanceTraveled: CLLocationDistance {
        return navigator.getTrackedRoutes().map { CLLocationDistance($0.distance) }.reduce(0, +) + routeProgress.distanceTraveled
    }
    
    var cumulativeTotalDistance: CLLocationDistance {
        return navigator.getTrackedRoutes().map { CLLocationDistance($0.distance) }.reduce(0, +) + route.distance
    }
    
    var cumulativeProgressCompleted: Double {
        return cumulativeDistanceTraveled / cumulativeTotalDistance
    }
    
    @objc public var config: MBNavigatorConfig? {
        get {
            return navigator.getConfig()
        }
        set {
            navigator.setConfigFor(newValue)
        }
    }
    
    /**
     Details about the user’s progress along the current route, leg, and step.
     */
    @objc public var routeProgress: RouteProgress {
        get {
            return _routeProgress
        }
        set {
            if let location = self.location {
                delegate?.router?(self, willRerouteFrom: location)
            }
            _routeProgress = newValue
            announce(reroute: routeProgress.route, at: dataSource.location, proactive: didFindFasterRoute)
        }
    }
    
    /**
     The raw location, snapped to the current route.
     - important: If the rawLocation is outside of the route snapping tolerances, this value is nil.
     */
    var snappedLocation: CLLocation? {
        let status = navigator.getStatusForTimestamp(Date())
        guard status.routeState == .tracking || status.routeState == .complete else {
            return nil
        }
        return CLLocation(status.location)
    }
    
    var heading: CLHeading?
    
    /**
     The most recently received user location.
     - note: This is a raw location received from `locationManager`. To obtain an idealized location, use the `location` property.
     */
    var rawLocation: CLLocation? {
        didSet {
            if isFirstLocation == true {
                isFirstLocation = false
            }
        }
    }
    
    /**
     The route controller’s delegate.
     */
    @objc public weak var delegate: RouterDelegate?
    
    /**
     The route controller’s associated location manager.
     */
    @objc public unowned var dataSource: RouterDataSource
    
    /**
     The Directions object used to create the route.
     */
    @objc public var directions: Directions
    
    /**
     The idealized user location. Snapped to the route line, if applicable, otherwise raw.
     - seeAlso: snappedLocation, rawLocation
     */
    @objc public var location: CLLocation? {
        return snappedLocation ?? rawLocation
    }
    
    required public init(along route: Route, directions: Directions = Directions.shared, dataSource source: RouterDataSource) {
        self.directions = directions
        self._routeProgress = RouteProgress(route: route)
        self.dataSource = source
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        super.init()
        
        updateNavigator()
    }
    
    func updateNavigator() {
        assert(route.json != nil, "route.json missing, please verify the version of MapboxDirections.swift")
        
        let data = try! JSONSerialization.data(withJSONObject: route.json!, options: [])
        let jsonString = String(data: data, encoding: .utf8)!
        
        // TODO: Add support for alternative route
        navigator.setRouteForRouteResponse(jsonString, route: 0, leg: 0)
    }
    
    func getDirections(from location: CLLocation, along progress: RouteProgress, completion: @escaping (Route?, Error?) -> Void) {
        routeTask?.cancel()
        let options = progress.reroutingOptions(with: location)
        
        self.lastRerouteLocation = location
        
        let complete = { [weak self] (route: Route?, error: NSError?) in
            self?.isRerouting = false
            completion(route, error)
        }
        
        routeTask = directions.calculate(options) {(waypoints, potentialRoutes, potentialError) in
            guard let routes = potentialRoutes else {
                complete(nil, potentialError)
                return
            }
            
            let mostSimilar = routes.mostSimilar(to: progress.route)
            
            complete(mostSimilar ?? routes.first, potentialError)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last else { return }
        
        guard delegate?.router?(self, shouldDiscard: location) ?? DefaultBehavior.shouldDiscardLocation else {
            return
        }
        
        rawLocation = locations.last
        
        locations.forEach { navigator.updateLocation(for: MBFixLocation($0)) }
        
        let status = navigator.getStatusForTimestamp(location.timestamp)
        
        let currentStepProgress = routeProgress.currentLegProgress.currentStepProgress
        currentStepProgress.intersectionIndex = Int(status.intersectionIndex)
        
        // Notify observers if the step’s remaining distance has changed.
        update(progress: routeProgress, with: CLLocation(status.location), rawLocation: location)
        
        let willReroute = !userIsOnRoute(location) && delegate?.router?(self, shouldRerouteFrom: location)
                          ?? DefaultBehavior.shouldRerouteFromLocation
        
        updateSpokenInstructionProgress(status: status, willReRoute: willReroute)
        updateRouteStepProgress(status: status)
        updateRouteLegProgress(status: status)
        updateVisualInstructionProgress(status: status)
        
        if willReroute {
            reroute(from: location, along: routeProgress)
        }
    }
    
    func updateSpokenInstructionProgress(status: MBNavigationStatus, willReRoute: Bool) {
        
        if let voiceInstructionIndex = status.voiceInstruction?.index {
            routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex = Int(voiceInstructionIndex)
            
            // Don't annouce spoken instruction if we are going to reroute
            if !willReRoute {
                announcePassage(of: routeProgress.currentLegProgress.currentStepProgress.currentSpokenInstruction!, routeProgress: routeProgress)
            }
        }
    }
    
    func updateVisualInstructionProgress(status: MBNavigationStatus) {
        
        let willChangeVisualIndex = status.bannerInstruction != nil
        
        if willChangeVisualIndex || isFirstLocation {
            let currentStepProgress = routeProgress.currentLegProgress.currentStepProgress
            currentStepProgress.visualInstructionIndex = Int(status.bannerInstruction?.index ?? 0)
            
            if let instruction = currentStepProgress.currentVisualInstruction {
                announcePassage(of: instruction, routeProgress: routeProgress)
            }
        }
    }
    
    func updateRouteLegProgress(status: MBNavigationStatus) {
        
        let legProgress = routeProgress.currentLegProgress
        let currentDestination = routeProgress.currentLeg.destination
        guard let remainingVoiceInstructions = legProgress.currentStepProgress.remainingSpokenInstructions else { return }
        
        // We are at least at the "You will arrive" instruction
        if legProgress.remainingSteps.count <= 2 && remainingVoiceInstructions.count <= 2 {
            
            let willArrive = status.routeState == .tracking
            let didArrive = status.routeState == .complete && currentDestination != previousArrivalWaypoint
            
            if willArrive {
                
                delegate?.router?(self, willArriveAt: currentDestination, after: legProgress.durationRemaining, distance: legProgress.distanceRemaining)
                
            } else if didArrive {
                
                previousArrivalWaypoint = currentDestination
                legProgress.userHasArrivedAtWaypoint = true
                
                let advancesToNextLeg = delegate?.router?(self, didArriveAt: currentDestination) ?? DefaultBehavior.didArriveAtWaypoint
                guard !routeProgress.isFinalLeg && advancesToNextLeg else { return }
                
                if advancesToNextLeg {
                    let legIndex = status.legIndex + 1
                    navigator.changeRouteLeg(forRoute: 0, leg: legIndex)
                    routeProgress.legIndex = Int(legIndex)
                }
            }
        }
    }
    
    func updateRouteStepProgress(status: MBNavigationStatus) {
        let stepIndex: Int = Int(status.stepIndex)
        
        if stepIndex != routeProgress.currentLegProgress.stepIndex {
            advanceStepIndex(to: stepIndex)
        }
    }
    
    func advanceStepIndex(to index: Array<RouteStep>.Index? = nil) {
        
        if let index = index {
            routeProgress.currentLegProgress.stepIndex = index
        } else {
            let status = navigator.getStatusForTimestamp(Date())
            routeProgress.currentLegProgress.stepIndex = Int(status.stepIndex)
        }
    }
    
    private func update(progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        
        let stepProgress = progress.currentLegProgress.currentStepProgress
        let step = stepProgress.step
        
        //Increment the progress model
        let polyline = Polyline(step.coordinates!)
        if let closestCoordinate = polyline.closestCoordinate(to: rawLocation.coordinate) {
            let remainingDistance = polyline.distance(from: closestCoordinate.coordinate)
            let distanceTraveled = step.distance - remainingDistance
            stepProgress.distanceTraveled = distanceTraveled
            
            //Fire the delegate method
            delegate?.router?(self, didUpdate: progress, with: location, rawLocation: rawLocation)
            
            //Fire the notification (for now)
            NotificationCenter.default.post(name: .routeControllerProgressDidChange, object: self, userInfo: [
                RouteControllerNotificationUserInfoKey.routeProgressKey: progress,
                RouteControllerNotificationUserInfoKey.locationKey: location, //guaranteed value
                RouteControllerNotificationUserInfoKey.rawLocationKey: rawLocation //raw
                ])
        }
    }
    
    private func announce(reroute newRoute: Route, at location: CLLocation?, proactive: Bool) {
        var userInfo = [RouteControllerNotificationUserInfoKey: Any]()
        if let location = location {
            userInfo[.locationKey] = location
        }
        userInfo[.isProactiveKey] = didFindFasterRoute
        NotificationCenter.default.post(name: .routeControllerDidReroute, object: self, userInfo: userInfo)
        delegate?.router?(self, didRerouteAlong: routeProgress.route, at: dataSource.location, proactive: didFindFasterRoute)
    }
    
    private func announcePassage(of spokenInstructionPoint: SpokenInstruction, routeProgress: RouteProgress) {
        
        delegate?.router?(self, didPassSpokenInstructionPoint: spokenInstructionPoint, routeProgress: routeProgress)
        
        let info: [RouteControllerNotificationUserInfoKey: Any] = [
            .routeProgressKey: routeProgress,
            .spokenInstructionKey: spokenInstructionPoint
        ]
        
        NotificationCenter.default.post(name: .routeControllerDidPassSpokenInstructionPoint, object: self, userInfo: info)
    }
    
    private func announcePassage(of visualInstructionPoint: VisualInstructionBanner, routeProgress: RouteProgress) {
        
        delegate?.router?(self, didPassVisualInstructionPoint: visualInstructionPoint, routeProgress: routeProgress)
        
        let info: [RouteControllerNotificationUserInfoKey: Any] = [
            .routeProgressKey: routeProgress,
            .visualInstructionKey: visualInstructionPoint
        ]
        
        NotificationCenter.default.post(name: .routeControllerDidPassVisualInstructionPoint, object: self, userInfo: info)
    }
    
    public func advanceLegIndex(location: CLLocation) {
        let status = navigator.getStatusForTimestamp(location.timestamp)
        routeProgress.legIndex = Int(status.legIndex)
    }
    
    public func enableLocationRecording() {
        navigator.toggleHistoryFor(onOff: true)
    }
    
    public func disableLocationRecording() {
        navigator.toggleHistoryFor(onOff: false)
    }
    
    public func locationHistory() -> String {
        return navigator.getHistory()
    }
}

extension RouteController: Router {
    
    public func userIsOnRoute(_ location: CLLocation) -> Bool {
        
        // If the user has arrived, do not continue monitor reroutes, step progress, etc
        if routeProgress.currentLegProgress.userHasArrivedAtWaypoint &&
            (delegate?.router?(self, shouldPreventReroutesWhenArrivingAt: routeProgress.currentLeg.destination) ??
                DefaultBehavior.shouldPreventReroutesWhenArrivingAtWaypoint) {
            return true
        }
        
        let status = navigator.getStatusForTimestamp(location.timestamp)
        let offRoute = status.routeState == .offRoute
        return !offRoute
    }
    
    public func reroute(from location: CLLocation, along progress: RouteProgress) {
        if let lastRerouteLocation = lastRerouteLocation {
            guard location.distance(from: lastRerouteLocation) >= RouteControllerMaximumDistanceBeforeRecalculating else {
                return
            }
        }
        
        if isRerouting {
            return
        }
        
        isRerouting = true
        
        delegate?.router?(self, willRerouteFrom: location)
        NotificationCenter.default.post(name: .routeControllerWillReroute, object: self, userInfo: [
            RouteControllerNotificationUserInfoKey.locationKey: location
            ])
        
        self.lastRerouteLocation = location
        
        getDirections(from: location, along: progress) { [weak self] (route, error) in
            guard let strongSelf: RouteController = self else {
                return
            }
            
            if let error = error {
                strongSelf.delegate?.router?(strongSelf, didFailToRerouteWith: error)
                NotificationCenter.default.post(name: .routeControllerDidFailToReroute, object: self, userInfo: [
                    RouteControllerNotificationUserInfoKey.routingErrorKey: error
                    ])
                return
            }
            
            guard let route = route else { return }
            strongSelf.isRerouting = false
            strongSelf._routeProgress = RouteProgress(route: route, legIndex: 0)
            strongSelf._routeProgress.currentLegProgress.stepIndex = 0
            strongSelf.announce(reroute: route, at: location, proactive: false)
        }
    }
}
