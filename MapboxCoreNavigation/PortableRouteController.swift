import Foundation
import CoreLocation
import MapboxNavigationNative
import MapboxMobileEvents
import MapboxDirections
import Polyline
import Turf


@objc(MBPortableRouteController)
open class PortableRouteController: NSObject {
    
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
        }
    }
    
    var movementsAwayFromRoute = 0
    
    var routeTask: URLSessionDataTask?
    
    var lastRerouteLocation: CLLocation?
    
    var didFindFasterRoute = false
    
    var isRerouting = false
    
    var userSnapToStepDistanceFromManeuver: CLLocationDistance?
    
    var previousArrivalWaypoint: Waypoint?
    
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
            // TODO: Verify we need to update distanceToManeuver
            //updateDistanceToManeuver()
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
    
    func updateNavigator() {
        assert(route.json != nil, "route.json missing, please verify the version of MapboxDirections.swift")
        
        let data = try! JSONSerialization.data(withJSONObject: route.json!, options: [])
        let jsonString = String(data: data, encoding: .utf8)!
        
        // TODO: Add support for alternative route
        navigator.setRouteForRouteResponse(jsonString, route: 0, leg: 0)
    }
    
    public required init(along route: Route, directions: Directions, dataSource source: RouterDataSource) {
        self.directions = directions
        self._routeProgress = RouteProgress(route: route)
        self.dataSource = source
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        super.init()
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
        
        guard delegate?.router?(self, shouldDiscard: location) ?? RouteController.DefaultBehavior.shouldDiscardLocation else {
            return
        }
        
        rawLocation = locations.last
        
        locations.forEach { navigator.updateLocation(for: MBFixLocation($0)) }
        
        let status = navigator.getStatusForTimestamp(location.timestamp)
        
        let currentStepProgress = routeProgress.currentLegProgress.currentStepProgress
        currentStepProgress.intersectionIndex = Int(status.intersectionIndex)
        
        // Notify observers if the step’s remaining distance has changed.
        update(progress: routeProgress, with: CLLocation(status), rawLocation: location)
        updateDistanceToIntersection(from: location)
        updateRouteStepProgress(for: location)
        updateRouteLegProgress(for: location)
        updateVisualInstructionProgress(for: location)
        updateRouteLegProgress(for: location)
        updateVisualInstructionProgress(for: location)
    }
    
    func updateVisualInstructionProgress(for location: CLLocation) {
        guard let userSnapToStepDistanceFromManeuver = userSnapToStepDistanceFromManeuver else { return }
        guard let visualInstructions = routeProgress.currentLegProgress.currentStepProgress.remainingVisualInstructions else { return }
        
        let firstInstructionOnFirstStep = routeProgress.currentLegProgress.stepIndex == 0 && routeProgress.currentLegProgress.currentStepProgress.visualInstructionIndex == 0
        
        for visualInstruction in visualInstructions {
            if userSnapToStepDistanceFromManeuver <= visualInstruction.distanceAlongStep || firstInstructionOnFirstStep {
                
                NotificationCenter.default.post(name: .routeControllerDidPassVisualInstructionPoint, object: self, userInfo: [
                    RouteControllerNotificationUserInfoKey.routeProgressKey: routeProgress
                    ])
                
                let status = navigator.getStatusForTimestamp(location.timestamp)
                
                if let visualInstructionIndex = status.voiceInstruction?.index {
                    routeProgress.currentLegProgress.currentStepProgress.visualInstructionIndex = Int(visualInstructionIndex)
                }
                
                return
            }
        }
    }
    
    func updateRouteLegProgress(for location: CLLocation) {
        let currentDestination = routeProgress.currentLeg.destination
        let legProgress = routeProgress.currentLegProgress
        guard let remainingVoiceInstructions = legProgress.currentStepProgress.remainingSpokenInstructions else { return }
        
        // We are at least at the "You will arrive" instruction
        if legProgress.remainingSteps.count <= 1 && remainingVoiceInstructions.count <= 1 && currentDestination != previousArrivalWaypoint {
            
            //Have we actually arrived? Last instruction is "You have arrived"
            if remainingVoiceInstructions.count == 0, legProgress.durationRemaining <= waypointArrivalThreshold {
                previousArrivalWaypoint = currentDestination
                legProgress.userHasArrivedAtWaypoint = true
                
                let advancesToNextLeg = delegate?.router?(self, didArriveAt: currentDestination) ?? RouteController.DefaultBehavior.didArriveAtWaypoint
                
                guard !routeProgress.isFinalLeg && advancesToNextLeg else { return }
                advanceLegIndex(location: location)
                updateDistanceToManeuver()
                
            } else { //we are approaching the destination
                delegate?.router?(self, willArriveAt: currentDestination, after: legProgress.durationRemaining, distance: legProgress.distanceRemaining)
            }
        }
    }
    
    func updateRouteStepProgress(for location: CLLocation) {
        guard routeProgress.currentLegProgress.remainingSteps.count > 0 else { return }
        
        guard let userSnapToStepDistanceFromManeuver = userSnapToStepDistanceFromManeuver else { return }
        var courseMatchesManeuverFinalHeading = false
        
        // Bearings need to normalized so when the `finalHeading` is 359 and the user heading is 1,
        // we count this as within the `RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion`
        if let upcomingStep = routeProgress.currentLegProgress.upcomingStep, let finalHeading = upcomingStep.finalHeading, let initialHeading = upcomingStep.initialHeading {
            let initialHeadingNormalized = initialHeading.wrap(min: 0, max: 360)
            let finalHeadingNormalized = finalHeading.wrap(min: 0, max: 360)
            let userHeadingNormalized = location.course.wrap(min: 0, max: 360)
            let expectedTurningAngle = initialHeadingNormalized.difference(from: finalHeadingNormalized)
            
            // If the upcoming maneuver is fairly straight,
            // do not check if the user is within x degrees of the exit heading.
            // For ramps, their current heading will very close to the exit heading.
            // We need to wait until their moving away from the maneuver location instead.
            // We can do this by looking at their snapped distance from the maneuver.
            // Once this distance is zero, they are at more moving away from the maneuver location
            if expectedTurningAngle <= RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion {
                courseMatchesManeuverFinalHeading = userSnapToStepDistanceFromManeuver == 0
            } else {
                courseMatchesManeuverFinalHeading = finalHeadingNormalized.difference(from: userHeadingNormalized) <= RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion
            }
        }
        
        let step = routeProgress.currentLegProgress.upcomingStep?.maneuverLocation ?? routeProgress.currentLegProgress.currentStep.maneuverLocation
        let userAbsoluteDistance = step.distance(to: location.coordinate)
        let lastKnownUserAbsoluteDistance = routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation
        
        if userSnapToStepDistanceFromManeuver <= RouteControllerManeuverZoneRadius &&
            (courseMatchesManeuverFinalHeading || (userAbsoluteDistance > lastKnownUserAbsoluteDistance && lastKnownUserAbsoluteDistance > RouteControllerManeuverZoneRadius)) {
            advanceStepIndex()
        }
        
        routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation = userAbsoluteDistance
    }
    
    func advanceStepIndex(to index: Array<RouteStep>.Index? = nil) {
        
        if let index = index {
            routeProgress.currentLegProgress.stepIndex = index
        } else {
            let status = navigator.getStatusForTimestamp(Date())
            routeProgress.currentLegProgress.stepIndex = Int(status.stepIndex)
        }
        
        updateIntersectionDistances()
        updateDistanceToManeuver()
    }
    
    func updateDistanceToManeuver() {
        guard let coordinates = routeProgress.currentLegProgress.currentStep.coordinates, let coordinate = rawLocation?.coordinate else {
            userSnapToStepDistanceFromManeuver = nil
            return
        }
        userSnapToStepDistanceFromManeuver = Polyline(coordinates).distance(from: coordinate)
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
    
    // TODO: Try to replace with MapboxNavigationNative
    func updateDistanceToIntersection(from location: CLLocation) {
        guard var intersections = routeProgress.currentLegProgress.currentStepProgress.step.intersections else { return }
        let currentStepProgress = routeProgress.currentLegProgress.currentStepProgress
        
        // The intersections array does not include the upcoming maneuver intersection.
        if let upcomingStep = routeProgress.currentLegProgress.upcomingStep, let upcomingIntersection = upcomingStep.intersections, let firstUpcomingIntersection = upcomingIntersection.first {
            intersections += [firstUpcomingIntersection]
        }
        
        routeProgress.currentLegProgress.currentStepProgress.intersectionsIncludingUpcomingManeuverIntersection = intersections
        
        if let upcomingIntersection = routeProgress.currentLegProgress.currentStepProgress.upcomingIntersection {
            routeProgress.currentLegProgress.currentStepProgress.userDistanceToUpcomingIntersection = Polyline(currentStepProgress.step.coordinates!).distance(from: location.coordinate, to: upcomingIntersection.location)
        }
        
        if routeProgress.currentLegProgress.currentStepProgress.intersectionDistances == nil {
            routeProgress.currentLegProgress.currentStepProgress.intersectionDistances = [CLLocationDistance]()
            updateIntersectionDistances()
        }
    }
    
    // TODO: Try to replace with MapboxNavigationNative
    func updateIntersectionDistances() {
        if let coordinates = routeProgress.currentLegProgress.currentStep.coordinates, let intersections = routeProgress.currentLegProgress.currentStep.intersections {
            let polyline = Polyline(coordinates)
            let distances: [CLLocationDistance] = intersections.map { polyline.distance(from: coordinates.first, to: $0.location) }
            routeProgress.currentLegProgress.currentStepProgress.intersectionDistances = distances
        }
    }
    
    func userIsWithinRadiusOfRoute(location: CLLocation) -> Bool {
        let status = navigator.getStatusForTimestamp(location.timestamp)
        let offRoute = status.routeState == .offRoute
        return !offRoute
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
    
    /**
     Advances the leg index. This override also advances the leg index of the native navigator.
     
     This is a convienence method provided to advance the leg index of any given router without having to worry about the internal data structure of the router.
     */
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

extension PortableRouteController: Router {
    public func userIsOnRoute(_ location: CLLocation) -> Bool {
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
            guard let strongSelf: PortableRouteController = self else {
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

extension MBNavigationStatus {
    
    
}

extension CLLocation {
    
    convenience init(_ status: MBNavigationStatus) {
        self.init(coordinate: status.location,
                  altitude: 0,
                  horizontalAccuracy: 0,
                  verticalAccuracy: 0,
                  course: CLLocationDirection(status.bearing),
                  speed: 0,
                  timestamp: status.time)
    }
}
