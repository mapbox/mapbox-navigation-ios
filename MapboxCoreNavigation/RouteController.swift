import Foundation
import CoreLocation
import MapboxNavigationNative
import MapboxMobileEvents
import MapboxDirections
import Polyline
import Turf


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
    
    /**
     The threshold used when we determine when the user has arrived at the waypoint.
     By default, we claim arrival 5 seconds before the user is physically estimated to arrive.
     */
    @objc public var waypointArrivalThreshold: TimeInterval = 5.0
    
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
        return rawLocation?.snapped(to: routeProgress)
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
        // If there is no snapped location, and the rawLocation course is unqualified, use the user's heading as long as it is accurate.
        if snappedLocation == nil,
            let heading = heading,
            let loc = rawLocation,
            !loc.course.isQualified,
            heading.trueHeading.isQualified {
            return CLLocation(coordinate: loc.coordinate, altitude: loc.altitude, horizontalAccuracy: loc.horizontalAccuracy, verticalAccuracy: loc.verticalAccuracy, course: heading.trueHeading, speed: loc.speed, timestamp: loc.timestamp)
        }
        
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
        update(progress: routeProgress, with: CLLocation(status), rawLocation: location)
        
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
            NotificationCenter.default.post(name: .routeControllerDidPassSpokenInstructionPoint, object: self, userInfo: [
                RouteControllerNotificationUserInfoKey.routeProgressKey: routeProgress
                ])
        }
    }
    
    func updateVisualInstructionProgress(status: MBNavigationStatus) {
        
        let willChangeVisualIndex = status.bannerInstruction != nil
        
        if willChangeVisualIndex || isFirstLocation {
            routeProgress.currentLegProgress.currentStepProgress.visualInstructionIndex = Int(status.bannerInstruction?.index ?? 0)
            NotificationCenter.default.post(name: .routeControllerDidPassVisualInstructionPoint, object: self, userInfo: [
                RouteControllerNotificationUserInfoKey.routeProgressKey: routeProgress
                ])
        }
    }
    
    func updateRouteLegProgress(status: MBNavigationStatus) {
        
        let legProgress = routeProgress.currentLegProgress
        let currentDestination = routeProgress.currentLeg.destination
        guard let remainingVoiceInstructions = legProgress.currentStepProgress.remainingSpokenInstructions else { return }
        
        // We are at least at the "You will arrive" instruction
        if legProgress.remainingSteps.count <= 2 && remainingVoiceInstructions.count <= 2 {
            
            let willArrive = status.routeState == .tracking
            let didArrive = status.routeState == .complete && currentDestination != previousArrivalWaypoint && status.remainingLegDuration <= waypointArrivalThreshold
            
            if willArrive {
                
                delegate?.router?(self, willArriveAt: currentDestination, after: legProgress.durationRemaining, distance: legProgress.distanceRemaining)
                
            } else if didArrive {
                
                previousArrivalWaypoint = currentDestination
                legProgress.userHasArrivedAtWaypoint = true
                
                let advancesToNextLeg = delegate?.router?(self, didArriveAt: currentDestination) ?? DefaultBehavior.didArriveAtWaypoint
                guard !routeProgress.isFinalLeg && advancesToNextLeg else { return }
                
                routeProgress.legIndex = Int(status.legIndex)
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
