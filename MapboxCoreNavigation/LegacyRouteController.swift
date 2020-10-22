import Foundation
import CoreLocation
import MapboxDirections
import Polyline
import MapboxMobileEvents
import Turf

protocol RouteControllerDataSource: class {
    var location: CLLocation? { get }
    var locationProvider: NavigationLocationManager.Type { get }
}

@available(*, deprecated, renamed: "RouteController")
open class LegacyRouteController: NSObject, Router, InternalRouter, CLLocationManagerDelegate {
    
    public weak var delegate: RouterDelegate?

    public unowned var dataSource: RouterDataSource
    
    /**
     The Directions object used to create the route.
     */
    public var directions: Directions

    /**
     The threshold used when we determine when the user has arrived at the waypoint.
     By default, we claim arrival 5 seconds before the user is physically estimated to arrive.
     */
    public var waypointArrivalThreshold: TimeInterval = 5.0
    
    public var reroutesProactively = true
    
    public var refreshesRoute: Bool = true

    var didFindFasterRoute = false
    
    var lastProactiveRerouteDate: Date?
    
    var lastRouteRefresh: Date?

    public var routeProgress: RouteProgress {
        get {
            return _routeProgress
        }
        set {
            if let location = self.location {
                delegate?.router(self, willRerouteFrom: location)
            }
            _routeProgress = newValue
            announce(reroute: routeProgress.route, at: location, proactive: didFindFasterRoute)
        }
    }
    
    private var _routeProgress: RouteProgress {
        didSet {
            movementsAwayFromRoute = 0
        }
    }
    
    public var indexedRoute: IndexedRoute {
        get {
            return routeProgress.indexedRoute
        }
        set {
            routeProgress.indexedRoute = newValue
        }
    }
    
    public var route: Route {
        return indexedRoute.0
    }

    var isRerouting = false
    var isRefreshing = false
    var lastRerouteLocation: CLLocation?

    var routeTask: URLSessionDataTask?
    var lastLocationDate: Date?

    var hasFoundOneQualifiedLocation = false

    var movementsAwayFromRoute = 0

    var previousArrivalWaypoint: Waypoint?
    
    var isFirstLocation: Bool = true

    var userSnapToStepDistanceFromManeuver: CLLocationDistance?
    
    required public init(along route: Route,
                         routeIndex: Int,
                         options: RouteOptions,
                         directions: Directions = Directions.shared,
                         dataSource source: RouterDataSource,
                         tilesVersion: String? = nil) {
        self.directions = directions
        self._routeProgress = RouteProgress(route: route, routeIndex: routeIndex, options: options)
        self.dataSource = source
        self.refreshesRoute = options.profileIdentifier == .automobileAvoidingTraffic && options.refreshingEnabled
        UIDevice.current.isBatteryMonitoringEnabled = true

        super.init()
        
        checkForUpdates()
        checkForLocationUsageDescription()
    }

    deinit {
        if let del = delegate, del.routerShouldDisableBatteryMonitoring(self) {
            UIDevice.current.isBatteryMonitoringEnabled = false
        }
    }
    
    public var location: CLLocation? {
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
    public var rawLocation: CLLocation? {
        didSet {
            if isFirstLocation == true {
                isFirstLocation = false
            }
            updateDistanceToManeuver()
        }
    }

    func updateDistanceToManeuver() {
        guard let shape = routeProgress.currentLegProgress.currentStep.shape, let coordinate = rawLocation?.coordinate else {
            userSnapToStepDistanceFromManeuver = nil
            return
        }
        userSnapToStepDistanceFromManeuver = shape.distance(from: coordinate)
    }

    public var reroutingTolerance: CLLocationDistance {
        guard let intersections = routeProgress.currentLegProgress.currentStepProgress.intersectionsIncludingUpcomingManeuverIntersection else { return RouteControllerMaximumDistanceBeforeRecalculating }
        guard let userLocation = rawLocation else { return RouteControllerMaximumDistanceBeforeRecalculating }

        for intersection in intersections {
            let absoluteDistanceToIntersection = userLocation.coordinate.distance(to: intersection.location)

            if absoluteDistanceToIntersection <= RouteControllerManeuverZoneRadius {
                return RouteControllerMaximumDistanceBeforeRecalculating / 2
            }
        }
        return RouteControllerMaximumDistanceBeforeRecalculating
    }
    
    /**
     Monitors the user's course to see if it is consistantly moving away from what we expect the course to be at a given point.
     */
    func userCourseIsOnRoute(_ location: CLLocation) -> Bool {
        let nearbyPolyline = routeProgress.nearbyShape
        guard let calculatedCourseForLocationOnStep = location.interpolatedCourse(along: nearbyPolyline) else { return true }
        
        let maxUpdatesAwayFromRouteGivenAccuracy = Int(location.horizontalAccuracy / Double(RouteControllerIncorrectCourseMultiplier))
        
        if movementsAwayFromRoute >= max(RouteControllerMinNumberOfInCorrectCourses, maxUpdatesAwayFromRouteGivenAccuracy)  {
            return false
        } else if location.shouldSnap(toRouteWith: calculatedCourseForLocationOnStep) {
            movementsAwayFromRoute = 0
        } else {
            movementsAwayFromRoute += 1
        }
        
        return true
    }
    
    public func userIsOnRoute(_ location: CLLocation) -> Bool {
        
        guard let destination = routeProgress.currentLeg.destination else {
            preconditionFailure("Route legs used for navigation must have destinations")
        }
        // If the user has arrived, do not continue monitor reroutes, step progress, etc
        if routeProgress.currentLegProgress.userHasArrivedAtWaypoint &&
            (delegate?.router(self, shouldPreventReroutesWhenArrivingAt: destination) ??
                RouteController.DefaultBehavior.shouldPreventReroutesWhenArrivingAtWaypoint) {
            return true
        }
        
        let isCloseToCurrentStep = userIsWithinRadiusOfRoute(location: location)
        
        guard !isCloseToCurrentStep || !userCourseIsOnRoute(location) else { return true }
        
        // Check and see if the user is near a future step.
        guard let nearestStep = routeProgress.currentLegProgress.closestStep(to: location.coordinate) else {
            return false
        }
        
        if nearestStep.distance < RouteControllerUserLocationSnappingDistance {
            // Only advance the stepIndex to a future step if the step is new. Otherwise, the user is still on the current step.
            if nearestStep.index != routeProgress.currentLegProgress.stepIndex {
                advanceStepIndex(to: nearestStep.index)
            }
            return true
        }
        
        return false
    }
    
    internal func userIsWithinRadiusOfRoute(location: CLLocation) -> Bool {
        let radius = max(reroutingTolerance, RouteControllerManeuverZoneRadius)
        let isCloseToCurrentStep = location.isWithin(radius, of: routeProgress.currentLegProgress.currentStep)
        return isCloseToCurrentStep
    }
    
    public func advanceLegIndex() {
        precondition(!routeProgress.isFinalLeg, "Can not increment leg index beyond final leg.")
        routeProgress.legIndex += 1
    }
    
    // MARK: CLLocationManagerDelegate methods
    
    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let filteredLocations = locations.filter {
            return $0.isQualified
        }

        if !filteredLocations.isEmpty, hasFoundOneQualifiedLocation == false {
            hasFoundOneQualifiedLocation = true
        }

        let currentStepProgress = routeProgress.currentLegProgress.currentStepProgress
        
        var potentialLocation: CLLocation?

        // `filteredLocations` contains qualified locations
        if let lastFiltered = filteredLocations.last {
            potentialLocation = lastFiltered
        // `filteredLocations` does not contain good locations and we have found at least one good location previously.
        } else if hasFoundOneQualifiedLocation {
            if let lastLocation = locations.last, delegate?.router(self, shouldDiscard: lastLocation) ?? RouteController.DefaultBehavior.shouldDiscardLocation {
                // Allow the user puck to advance. A stationary puck is not great.
                self.rawLocation = lastLocation
                
                return
            }
        // This case handles the first location.
        // This location is not a good location, but we need the rest of the UI to update and at least show something.
        } else if let lastLocation = locations.last {
            potentialLocation = lastLocation
        }

        guard let location = potentialLocation else {
            return
        }

        self.rawLocation = location

        updateIntersectionIndex(for: currentStepProgress)
        // Notify observers if the step’s remaining distance has changed.

        update(progress: routeProgress, with: self.location!, rawLocation: location)
        updateDistanceToIntersection(from: location)
        updateRouteStepProgress(for: location)
        updateRouteLegProgress(for: location)
        updateVisualInstructionProgress()

        if !userIsOnRoute(location) && delegate?.router(self, shouldRerouteFrom: location) ?? RouteController.DefaultBehavior.shouldRerouteFromLocation {
            reroute(from: location, along: routeProgress)
            return
        }

        updateSpokenInstructionProgress()
        
        // Check for faster route proactively (if reroutesProactively is enabled)
        refreshAndCheckForFasterRoute(from: location, routeProgress: routeProgress)
    }
    
    private func update(progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        progress.updateDistanceTraveled(with: rawLocation)
        
        //Fire the delegate method
        delegate?.router(self, didUpdate: progress, with: location, rawLocation: rawLocation)
        
        //Fire the notification (for now)
        NotificationCenter.default.post(name: .routeControllerProgressDidChange, object: self, userInfo: [
            RouteController.NotificationUserInfoKey.routeProgressKey: progress,
            RouteController.NotificationUserInfoKey.locationKey: location, //guaranteed value
            RouteController.NotificationUserInfoKey.rawLocationKey: rawLocation, //raw
        ])
    }
        
    func updateIntersectionIndex(for currentStepProgress: RouteStepProgress) {
        guard let intersectionDistances = currentStepProgress.intersectionDistances else { return }
        let upcomingIntersectionIndex = intersectionDistances.firstIndex { $0 > currentStepProgress.distanceTraveled } ?? intersectionDistances.endIndex
        currentStepProgress.intersectionIndex = upcomingIntersectionIndex > 0 ? intersectionDistances.index(before: upcomingIntersectionIndex) : 0
    }

    func updateRouteLegProgress(for location: CLLocation) {
        
        let legProgress = routeProgress.currentLegProgress
        guard let currentDestination = legProgress.leg.destination else {
            preconditionFailure("Route legs used for navigation must have destinations")
        }
        guard let remainingVoiceInstructions = legProgress.currentStepProgress.remainingSpokenInstructions else {
            return
        }

        // We are at least at the "You will arrive" instruction
        if legProgress.remainingSteps.count <= 1 && remainingVoiceInstructions.count <= 1 && currentDestination != previousArrivalWaypoint {
            //Have we actually arrived? Last instruction is "You have arrived"
            if remainingVoiceInstructions.count == 0, legProgress.durationRemaining <= waypointArrivalThreshold {
                previousArrivalWaypoint = currentDestination
                legProgress.userHasArrivedAtWaypoint = true
                
                let advancesToNextLeg = delegate?.router(self, didArriveAt: currentDestination) ?? RouteController.DefaultBehavior.didArriveAtWaypoint
                
                guard !routeProgress.isFinalLeg && advancesToNextLeg else { return }
                advanceLegIndex()
                updateDistanceToManeuver()
            } else { //we are approaching the destination
                delegate?.router(self, willArriveAt: currentDestination, after: legProgress.durationRemaining, distance: legProgress.distanceRemaining)
            }
        }
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

        delegate?.router(self, willRerouteFrom: location)
        NotificationCenter.default.post(name: .routeControllerWillReroute, object: self, userInfo: [
            RouteController.NotificationUserInfoKey.locationKey: location,
        ])

        self.lastRerouteLocation = location

        getDirections(from: location, along: progress) { [weak self] (session, result) in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.isRerouting = false
            switch result {
            case let .failure(error):
                strongSelf.delegate?.router(strongSelf, didFailToRerouteWith: error)
                 NotificationCenter.default.post(name: .routeControllerDidFailToReroute, object: self, userInfo: [
                     RouteController.NotificationUserInfoKey.routingErrorKey: error,
                 ])
                 return
            case let .success(response):
                guard case let .route(options) = response.options, let route = response.routes?.first else {
                    return
                }
                strongSelf.indexedRoute = (route, 0) // unconditionally getting the first route above
                strongSelf._routeProgress = RouteProgress(route: route, routeIndex: 0, options: options, legIndex: 0)
                strongSelf._routeProgress.currentLegProgress.stepIndex = 0
                strongSelf.announce(reroute: route, at: location, proactive: false)
            }
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

    func updateDistanceToIntersection(from location: CLLocation) {
        guard var intersections = routeProgress.currentLegProgress.currentStepProgress.step.intersections else { return }
        let currentStepProgress = routeProgress.currentLegProgress.currentStepProgress

        // The intersections array does not include the upcoming maneuver intersection.
        if let upcomingStep = routeProgress.currentLegProgress.upcomingStep, let upcomingIntersection = upcomingStep.intersections, let firstUpcomingIntersection = upcomingIntersection.first {
            intersections += [firstUpcomingIntersection]
        }

        routeProgress.currentLegProgress.currentStepProgress.intersectionsIncludingUpcomingManeuverIntersection = intersections

        guard let shape = currentStepProgress.step.shape else {
            return
        }
        
        if let upcomingIntersection = routeProgress.currentLegProgress.currentStepProgress.upcomingIntersection {
            routeProgress.currentLegProgress.currentStepProgress.userDistanceToUpcomingIntersection = shape.distance(from: location.coordinate, to: upcomingIntersection.location)
        }
        
        if routeProgress.currentLegProgress.currentStepProgress.intersectionDistances == nil {
            routeProgress.currentLegProgress.currentStepProgress.intersectionDistances = [CLLocationDistance]()
            updateIntersectionDistances()
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
            let expectedTurningAngle = initialHeadingNormalized.difference(from: finalHeadingNormalized)

            // If the upcoming maneuver is fairly straight,
            // do not check if the user is within x degrees of the exit heading.
            // For ramps, their current heading will very close to the exit heading.
            // We need to wait until their moving away from the maneuver location instead.
            // We can do this by looking at their snapped distance from the maneuver.
            // Once this distance is zero, they are at more moving away from the maneuver location
            if expectedTurningAngle <= RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion {
                courseMatchesManeuverFinalHeading = userSnapToStepDistanceFromManeuver == 0
            } else if location.course.isQualified {
                let userHeadingNormalized = location.course.wrap(min: 0, max: 360)
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

    func updateSpokenInstructionProgress() {
        guard let userSnapToStepDistanceFromManeuver = userSnapToStepDistanceFromManeuver else { return }
        guard let spokenInstructions = routeProgress.currentLegProgress.currentStepProgress.remainingSpokenInstructions else { return }

        // Always give the first voice announcement when beginning a leg.
        let firstInstructionOnFirstStep = routeProgress.currentLegProgress.stepIndex == 0 && routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex == 0

        for spokenInstruction in spokenInstructions {
            if userSnapToStepDistanceFromManeuver <= spokenInstruction.distanceAlongStep || firstInstructionOnFirstStep {
                delegate?.router(self, didPassSpokenInstructionPoint: spokenInstruction, routeProgress: routeProgress)
                NotificationCenter.default.post(name: .routeControllerDidPassSpokenInstructionPoint, object: self, userInfo: [
                    RouteController.NotificationUserInfoKey.routeProgressKey: routeProgress,
                    RouteController.NotificationUserInfoKey.spokenInstructionKey: spokenInstruction,
                ])

                routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex += 1
                return
            }
        }
    }
    
    func updateVisualInstructionProgress() {
        guard let userSnapToStepDistanceFromManeuver = userSnapToStepDistanceFromManeuver else { return }
        let currentStepProgress = routeProgress.currentLegProgress.currentStepProgress
        guard let visualInstructions = currentStepProgress.remainingVisualInstructions else { return }
        
        for visualInstruction in visualInstructions {
            if userSnapToStepDistanceFromManeuver <= visualInstruction.distanceAlongStep || isFirstLocation {
                delegate?.router(self, didPassVisualInstructionPoint: visualInstruction, routeProgress: routeProgress)
                NotificationCenter.default.post(name: .routeControllerDidPassVisualInstructionPoint, object: self, userInfo: [
                    RouteController.NotificationUserInfoKey.routeProgressKey: routeProgress,
                    RouteController.NotificationUserInfoKey.visualInstructionKey: visualInstruction,
                ])
                currentStepProgress.visualInstructionIndex += 1
                return
            }
        }
    }

    func advanceStepIndex(to: Array<RouteStep>.Index? = nil) {
        if let forcedStepIndex = to {
            guard forcedStepIndex < routeProgress.currentLeg.steps.count else { return }
            routeProgress.currentLegProgress.stepIndex = forcedStepIndex
        } else {
            routeProgress.currentLegProgress.stepIndex += 1
        }

        updateIntersectionDistances()
        updateDistanceToManeuver()
    }

    func updateIntersectionDistances() {
        if let shape = routeProgress.currentLegProgress.currentStep.shape, let intersections = routeProgress.currentLegProgress.currentStep.intersections {
            let distances: [CLLocationDistance] = intersections.compactMap { shape.distance(from: shape.coordinates.first, to: $0.location) }
            routeProgress.currentLegProgress.currentStepProgress.intersectionDistances = distances
        }
    }
    
    // MARK: Obsolete methods
    
    @available(swift, obsoleted: 0.1, message: "MapboxNavigationService is now the point-of-entry to MapboxCoreNavigation. Direct use of RouteController is no longer reccomended. See MapboxNavigationService for more information.")
    /// :nodoc: Obsoleted method.
    public convenience init(along route: Route, directions: Directions = Directions.shared, dataSource: NavigationLocationManager = NavigationLocationManager(), eventsManager: NavigationEventsManager) {
        fatalError()
    }
    
    @available(swift, obsoleted: 0.1, message: "RouteController no longer manages a location manager directly. Instead, the Router protocol conforms to CLLocationManagerDelegate, and RouteControllerDataSource provides access to synchronous location requests.")
    /// :nodoc: obsoleted
    public final var locationManager: NavigationLocationManager! {
        get {
            fatalError()
        }
        set {
            fatalError()
        }
    }
    @available(swift, obsoleted: 0.1, message: "NavigationViewController no longer directly manages a TunnelIntersectionManager. See MapboxNavigationService, which contains a reference to the locationManager, for more information.")
    /// :nodoc: obsoleted
    public final var tunnelIntersectionManager: Any! {
        get {
            fatalError()
        }
        set {
            fatalError()
        }
    }
    @available(swift, obsoleted: 0.1, renamed: "navigationService.eventsManager", message: "NavigationViewController no longer directly manages a NavigationEventsManager. See MapboxNavigationService, which contains a reference to the eventsManager, for more information.")
    /// :nodoc: obsoleted
    public final var eventsManager: NavigationEventsManager! {
        get {
            fatalError()
        }
        set {
            fatalError()
        }
    }
    
    /// Required through `Router` protocol. No-op
    public func enableLocationRecording() {
        // no-op
    }
    /// Required through `Router` protocol. No-op

    public func disableLocationRecording() {
        // no-op
    }
    
    /// Required through `Router` protocol. No-op
    public func locationHistory() -> String? {
        return nil
    }
}
