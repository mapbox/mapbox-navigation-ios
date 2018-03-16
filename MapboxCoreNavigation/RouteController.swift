import Foundation
import CoreLocation
import MapboxDirections
import Polyline
import MapboxMobileEvents
import Turf

/**
 Keys in the user info dictionaries of various notifications posted by instances
 of `RouteController`.
 */
public typealias RouteControllerNotificationUserInfoKey = MBRouteControllerNotificationUserInfoKey

extension Notification.Name {
    /**
     Posted when `RouteController` fails to reroute the user after the user diverges from the expected route.
     
     The user info dictionary contains the key `RouteControllerNotificationUserInfoKey.errorKey`.
     */
    public static let routeControllerDidFailToReroute = MBRouteControllerDidFailToReroute
    
    /**
     Posted after the user diverges from the expected route, just before `RouteController` attempts to calculate a new route.
     
     The user info dictionary contains the key `RouteControllerNotificationUserInfoKey.locationKey`.
     */
    public static let routeControllerWillReroute = MBRouteControllerWillReroute
    
    /**
     Posted when `RouteController` obtains a new route in response to the user diverging from a previous route.
     
     The user info dictionary contains the keys `RouteControllerNotificationUserInfoKey.locationKey` and `RouteControllerNotificationUserInfoKey.isProactiveKey`.
     */
    public static let routeControllerDidReroute = MBRouteControllerDidReroute
    
    /**
     Posted when `RouteController` receives a user location update representing movement along the expected route.
     
     The user info dictionary contains the keys `RouteControllerNotificationUserInfoKey.routeProgressKey`, `RouteControllerNotificationUserInfoKey.locationKey`, and `RouteControllerNotificationUserInfoKey.rawLocationKey`.
     */
    public static let routeControllerProgressDidChange = MBRouteControllerProgressDidChange
    
    /**
     Posted when `RouteController` detects that the user has passed an ideal point for saying an instruction aloud.
     
     The user info dictionary contains the key `RouteControllerNotificationUserInfoKey.routeProgressKey`.
     */
    public static let routeControllerDidPassSpokenInstructionPoint = MBRouteControllerDidPassSpokenInstructionPoint
}

/**
 The `RouteControllerDelegate` class provides methods for responding to significant occasions during the user’s traversal of a route monitored by a `RouteController`.
 */
@objc(MBRouteControllerDelegate)
public protocol RouteControllerDelegate: class {
    /**
     Returns whether the route controller should be allowed to calculate a new route.

     If implemented, this method is called as soon as the route controller detects that the user is off the predetermined route. Implement this method to conditionally prevent rerouting. If this method returns `true`, `routeController(_:willRerouteFrom:)` will be called immediately afterwards.

     - parameter routeController: The route controller that has detected the need to calculate a new route.
     - parameter location: The user’s current location.
     - returns: True to allow the route controller to calculate a new route; false to keep tracking the current route.
     */
    @objc(routeController:shouldRerouteFromLocation:)
    optional func routeController(_ routeController: RouteController, shouldRerouteFrom location: CLLocation) -> Bool

    /**
     Called immediately before the route controller calculates a new route.

     This method is called after `routeController(_:shouldRerouteFrom:)` is called, simultaneously with the `RouteControllerWillReroute` notification being posted, and before `routeController(_:didRerouteAlong:)` is called.

     - parameter routeController: The route controller that will calculate a new route.
     - parameter location: The user’s current location.
     */
    @objc(routeController:willRerouteFromLocation:)
    optional func routeController(_ routeController: RouteController, willRerouteFrom location: CLLocation)

    /**
     Called when a location has been identified as unqualified to navigate on.

     See `CLLocation.isQualified` for more information about what qualifies a location.

     - parameter routeController: The route controller that discarded the location.
     - parameter location: The location that will be discarded.
     - return: If `true`, the location is discarded and the `RouteController` will not consider it. If `false`, the location will not be thrown out.
     */
    @objc(routeController:shouldDiscardLocation:)
    optional func routeController(_ routeController: RouteController, shouldDiscard location: CLLocation) -> Bool

    /**
     Called immediately after the route controller receives a new route.

     This method is called after `routeController(_:willRerouteFrom:)` and simultaneously with the `RouteControllerDidReroute` notification being posted.

     - parameter routeController: The route controller that has calculated a new route.
     - parameter route: The new route.
     */
    @objc(routeController:didRerouteAlongRoute:)
    optional func routeController(_ routeController: RouteController, didRerouteAlong route: Route)

    /**
     Called when the route controller fails to receive a new route.

     This method is called after `routeController(_:willRerouteFrom:)` and simultaneously with the `RouteControllerDidFailToReroute` notification being posted.

     - parameter routeController: The route controller that has calculated a new route.
     - parameter error: An error raised during the process of obtaining a new route.
     */
    @objc(routeController:didFailToRerouteWithError:)
    optional func routeController(_ routeController: RouteController, didFailToRerouteWith error: Error)

    /**
     Called when the route controller’s location manager receive a location update.

     These locations can be modified due to replay or simulation but they can
     also derive from regular location updates from a `CLLocationManager`.

     - parameter routeController: The route controller that received the new locations.
     - parameter locations: The locations that were received from the associated location manager.
     */
    @objc(routeController:didUpdateLocations:)
    optional func routeController(_ routeController: RouteController, didUpdate locations: [CLLocation])
    
    /**
     Called when the route controller arrives at a waypoint.
     
     You can implement this method to prevent the route controller from automatically advancing to the next leg. For example, you can and show an interstitial sheet upon arrival and pause navigation by returning `false`, then continue the route when the user dismisses the sheet. If this method is unimplemented, the route controller automatically advances to the next leg when arriving at a waypoint.
     
     - postcondition: If you return false, you must manually advance to the next leg: obtain the value of the `routeProgress` property, then increment the `RouteProgress.legIndex` property.
     - parameter routeController: The route controller that has arrived at a waypoint.
     - parameter waypoint: The waypoint that the controller has arrived at.
     - returns: True to advance to the next leg, if any, or false to remain on the completed leg.
    */
    @objc(routeController:didArriveAtWaypoint:)
    optional func routeController(_ routeController: RouteController, didArriveAt waypoint: Waypoint) -> Bool
}

/**
 A `RouteController` tracks the user’s progress along a route, posting notifications as the user reaches significant points along the route. On every location update, the route controller evaluates the user’s location, determining whether the user remains on the route. If not, the route controller calculates a new route.

 `RouteController` is responsible for the core navigation logic whereas
 `NavigationViewController` is responsible for displaying a default drop-in navigation UI.
 */
@objc(MBRouteController)
open class RouteController: NSObject {
    let events = MMEEventsManager.shared()

    /**
     The route controller’s delegate.
     */
    @objc public weak var delegate: RouteControllerDelegate?

    /**
     The Directions object used to create the route.
     */
    @objc public var directions: Directions

    /**
     The route controller’s associated location manager.
     */
    @objc public var locationManager: NavigationLocationManager! {
        didSet {
            oldValue?.delegate = nil
            locationManager.delegate = self
        }
    }

    /**
     If true, location updates will be simulated when driving through tunnels or other areas where there is none or bad GPS reception.
     */
    @objc public var isDeadReckoningEnabled = false

    /**
     If true, the `RouteController` attempts to calculate a more optimal route for the user on an interval defined by `RouteControllerProactiveReroutingInterval`.
     */
    @objc public var reroutesProactively = false

    var didFindFasterRoute = false

    /**
     Details about the user’s progress along the current route, leg, and step.
     */
    public var routeProgress: RouteProgress {
        willSet {
            // Save any progress completed up until now
            sessionState.totalDistanceCompleted += routeProgress.distanceTraveled
        }
        didSet {
            // if the user has already arrived and a new route has been set, restart the navigation session
            if sessionState.arrivalTimestamp != nil {
                resetSession()
            } else {
                sessionState.currentRoute = routeProgress.route
            }

            var userInfo = [RouteControllerNotificationUserInfoKey: Any]()
            if let location = locationManager.location {
                userInfo[.locationKey] = location
            }
            userInfo[.isProactiveKey] = didFindFasterRoute
            NotificationCenter.default.post(name: .routeControllerDidReroute, object: self, userInfo: userInfo)
        }
    }
    
    var endOfRouteStarRating: Int?
    var endOfRouteComment: String?

    var isRerouting = false
    var lastRerouteLocation: CLLocation?

    var routeTask: URLSessionDataTask?
    var lastLocationDate: Date?

    /// :nodoc: This is used internally when the navigation UI is being used
    public var usesDefaultUserInterface = false

    var sessionState: SessionState
    var outstandingFeedbackEvents = [CoreFeedbackEvent]()

    var hasFoundOneQualifiedLocation = false

    var movementsAwayFromRoute = 0
    
    var previousArrivalWaypoint: Waypoint? {
        didSet {
            if oldValue != previousArrivalWaypoint {
                sessionState.arrivalTimestamp = nil
                sessionState.departureTimestamp = nil
            }
        }
    }
    
    var userSnapToStepDistanceFromManeuver: CLLocationDistance?

    /**
     Intializes a new `RouteController`.

     - parameter route: The route to follow.
     - parameter directions: The Directions object that created `route`.
     - parameter locationManager: The associated location manager.
     */
    @objc(initWithRoute:directions:locationManager:)
    public init(along route: Route, directions: Directions = Directions.shared, locationManager: NavigationLocationManager = NavigationLocationManager()) {
        self.sessionState = SessionState(currentRoute: route, originalRoute: route)
        self.directions = directions
        self.routeProgress = RouteProgress(route: route)
        self.locationManager = locationManager
        self.locationManager.activityType = route.routeOptions.activityType
        UIDevice.current.isBatteryMonitoringEnabled = true
        super.init()

        self.locationManager.delegate = self
        self.resumeNotifications()
        self.resetSession()

        DispatchQueue.main.async {
            self.startEvents(route: route)
        }
        
        checkForUpdates()
        
        guard let _ = Bundle.main.bundleIdentifier else { return }
        if Bundle.main.locationAlwaysUsageDescription == nil && Bundle.main.locationWhenInUseUsageDescription == nil && Bundle.main.locationAlwaysAndWhenInUseUsageDescription == nil {
            preconditionFailure("This application’s Info.plist file must include a NSLocationWhenInUseUsageDescription. See https://developer.apple.com/documentation/corelocation for more information.")
        }
    }

    deinit {
        suspendLocationUpdates()
        sendCancelEvent(rating: endOfRouteStarRating, comment: endOfRouteComment)
        checkAndSendOutstandingFeedbackEvents(forceAll: true)
        suspendNotifications()
        UIDevice.current.isBatteryMonitoringEnabled = false
    }

    func startEvents(route: Route) {
        let eventLoggingEnabled = UserDefaults.standard.bool(forKey: NavigationMetricsDebugLoggingEnabled)

        var mapboxAccessToken: String? = nil
        if let accessToken = route.accessToken {
            mapboxAccessToken = accessToken
        } else if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
            let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject],
            let token = dict["MGLMapboxAccessToken"] as? String {
            mapboxAccessToken = token
        }

        if let mapboxAccessToken = mapboxAccessToken {
            events.isDebugLoggingEnabled = eventLoggingEnabled
            events.isMetricsEnabledInSimulator = true
            events.isMetricsEnabledForInUsePermissions = true
            let userAgent = usesDefaultUserInterface ? "mapbox-navigation-ui-ios" : "mapbox-navigation-ios"
            events.initialize(withAccessToken: mapboxAccessToken, userAgentBase: userAgent, hostSDKVersion: String(describing: Bundle(for: RouteController.self).object(forInfoDictionaryKey: "CFBundleShortVersionString")!))
            events.disableLocationMetrics()
            events.sendTurnstileEvent()
        } else {
            assert(false, "`accessToken` must be set in the Info.plist as `MGLMapboxAccessToken` or the `Route` passed into the `RouteController` must have the `accessToken` property set.")
        }
    }

    func resumeNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(notification:)), name: .routeControllerProgressDidChange, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(willReroute(notification:)), name: .routeControllerWillReroute, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(didReroute(notification:)), name: .routeControllerDidReroute, object: self)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeOrientation), name: .UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeApplicationState), name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didChangeApplicationState), name: .UIApplicationDidEnterBackground, object: nil)
    }

    func suspendNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func didChangeOrientation() {
        if UIDevice.current.orientation.isPortrait {
            sessionState.timeSpentInLandscape += abs(sessionState.lastTimeInPortrait.timeIntervalSinceNow)
            
            sessionState.lastTimeInPortrait = Date()
        } else if UIDevice.current.orientation.isLandscape {
            sessionState.timeSpentInPortrait += abs(sessionState.lastTimeInLandscape.timeIntervalSinceNow)
            
            sessionState.lastTimeInLandscape = Date()
        }
    }
    
    @objc func didChangeApplicationState() {
        if UIApplication.shared.applicationState == .active {
            sessionState.timeSpentInForeground += abs(sessionState.lastTimeInBackground.timeIntervalSinceNow)
            
            sessionState.lastTimeInForeground = Date()
        } else if UIApplication.shared.applicationState == .background {
            sessionState.timeSpentInBackground += abs(sessionState.lastTimeInForeground.timeIntervalSinceNow)
            
            sessionState.lastTimeInBackground = Date()
        }
    }

    /**
     Starts monitoring the user’s location along the route.

     Will continue monitoring until `suspendLocationUpdates()` is called.
     */
    @objc public func resume() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    /**
     Stops monitoring the user’s location along the route.
     */
    @objc public func suspendLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    /**
     The idealized user location. Snapped to the route line, if applicable, otherwise raw.
     - seeAlso: snappedLocation, rawLocation
     */
    @objc public var location: CLLocation? {
        return snappedLocation ?? rawLocation
    }
    
    /**
     The raw location, snapped to the current route.
     - important: If the rawLocation is outside of the route snapping tolerances, this value is nil.
     */
    var snappedLocation: CLLocation? {
        return rawLocation?.snapped(to: routeProgress.currentLegProgress)
    }

    /**
     The most recently received user location.
     - note: This is a raw location received from `locationManager`. To obtain an idealized location, use the `location` property.
     */
    var rawLocation: CLLocation? {
        didSet {
            guard let coordinates = routeProgress.currentLegProgress.currentStep.coordinates, let coordinate = rawLocation?.coordinate else {
                userSnapToStepDistanceFromManeuver = nil
                return
            }
            userSnapToStepDistanceFromManeuver = Polyline(coordinates).distance(from: coordinate)
        }
    }

    @objc public var reroutingTolerance: CLLocationDistance {
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
     Send feedback about the current road segment/maneuver to the Mapbox data team.

     You can pair this with a custom feedback UI in your app to flag problems during navigation such as road closures, incorrect instructions, etc.

     @param type A `FeedbackType` used to specify the type of feedback
     @param description A custom string used to describe the problem in detail.
     @return Returns a UUID string used to identify the feedback event

     If you provide a custom feedback UI that lets users elaborate on an issue, you should call this before you show the custom UI so the location and timestamp are more accurate.

     You can then call `updateFeedback(feedbackId:)` with the returned feedback ID string to attach any additional metadata to the feedback.
     */
    @objc public func recordFeedback(type: FeedbackType = .general, description: String? = nil) -> String {
        return enqueueFeedbackEvent(type: type, description: description)
    }

    /**
     Update the feedback event with a specific feedback ID. If you implement a custom feedback UI that lets a user elaborate on an issue, you can use this to update the metadata.

     Note that feedback is sent 20 seconds after being recorded, so you should promptly update the feedback metadata after the user discards any feedback UI.
     */
    @objc public func updateFeedback(feedbackId: String, type: FeedbackType, source: FeedbackSource, description: String?) {
        if let lastFeedback = outstandingFeedbackEvents.first(where: { $0.id.uuidString == feedbackId}) as? FeedbackEvent {
            lastFeedback.update(type: type, source: source, description: description)
        }
    }

    /**
     Discard a recorded feedback event, for example if you have a custom feedback UI and the user cancelled feedback.
     */
    @objc public func cancelFeedback(feedbackId: String) {
        if let index = outstandingFeedbackEvents.index(where: {$0.id.uuidString == feedbackId}) {
            outstandingFeedbackEvents.remove(at: index)
        }
    }
    
    /**
     Set the rating and any comment the user may have about their route. Only used when exiting navigaiton.
     */
    @objc public func setEndOfRoute(rating: Int, comment: String?) {
        endOfRouteStarRating = rating
        endOfRouteComment = comment
    }
}

extension RouteController {
    @objc func progressDidChange(notification: NSNotification) {
        if sessionState.departureTimestamp == nil {
            sessionState.departureTimestamp = Date()
            sendDepartEvent()
        }
        
        if sessionState.arrivalTimestamp == nil,
            routeProgress.currentLegProgress.userHasArrivedAtWaypoint {
            sessionState.arrivalTimestamp = Date()
            sendArriveEvent()
        }
        
        checkAndSendOutstandingFeedbackEvents(forceAll: false)
    }

    @objc func willReroute(notification: NSNotification) {
        _ = enqueueRerouteEvent()
    }
    
    @objc func didReroute(notification: NSNotification) {
        if let didFindFasterRoute = notification.userInfo?[RouteControllerNotificationUserInfoKey.isProactiveKey] as? Bool, didFindFasterRoute {
            _ = enqueueFoundFasterRouteEvent()
        }
        
        if let lastReroute = outstandingFeedbackEvents.map({$0 as? RerouteEvent }).last {
            lastReroute?.update(newRoute: routeProgress.route)
        }
        
        movementsAwayFromRoute = 0
    }
}

extension RouteController: CLLocationManagerDelegate {

    @objc func interpolateLocation() {
        guard let location = locationManager.lastKnownLocation else { return }
        guard let coordinates = routeProgress.route.coordinates else { return }
        let polyline = Polyline(coordinates)

        let distance = location.speed as CLLocationDistance

        guard let interpolatedCoordinate = polyline.coordinateFromStart(distance: routeProgress.distanceTraveled+distance) else {
            return
        }

        var course = location.course
        if let upcomingCoordinate = polyline.coordinateFromStart(distance: routeProgress.distanceTraveled+(distance*2)) {
            course = interpolatedCoordinate.direction(to: upcomingCoordinate)
        }

        let interpolatedLocation = CLLocation(coordinate: interpolatedCoordinate,
                                              altitude: location.altitude,
                                              horizontalAccuracy: location.horizontalAccuracy,
                                              verticalAccuracy: location.verticalAccuracy,
                                              course: course,
                                              speed: location.speed,
                                              timestamp: Date())

        self.locationManager(self.locationManager, didUpdateLocations: [interpolatedLocation])
    }

    @objc public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let filteredLocations = locations.filter {
            sessionState.pastLocations.push($0)
            return $0.isQualified
        }
        
        if !filteredLocations.isEmpty, hasFoundOneQualifiedLocation == false {
            hasFoundOneQualifiedLocation = true
        }
        
        var potentialLocation: CLLocation?
        
        // `filteredLocations` contains qualified locations
        if let lastFiltered = filteredLocations.last {
            potentialLocation = lastFiltered
        // `filteredLocations` does not contain good locations and we have found at least one good location previously.
        } else if hasFoundOneQualifiedLocation {
            if let lastLocation = locations.last, delegate?.routeController?(self, shouldDiscard: lastLocation) ?? true {
                return
            }
        // This case handles the first location.
        // This location is not a good location, but we need the rest of the UI to update and at least show something.
        } else if let lastLocation = locations.last {
            potentialLocation = lastLocation
        }
        
        guard let location = potentialLocation else { return }
        
        self.rawLocation = location

        delegate?.routeController?(self, didUpdate: [location])

        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(interpolateLocation), object: nil)

        if isDeadReckoningEnabled {
            perform(#selector(interpolateLocation), with: nil, afterDelay: 1.1)
        }

        let polyline = Polyline(routeProgress.currentLegProgress.currentStep.coordinates!)
        let currentStepProgress = routeProgress.currentLegProgress.currentStepProgress
        let currentStep = currentStepProgress.step

        updateIntersectionIndex(for: currentStepProgress)
        
        // Notify observers if the step’s remaining distance has changed.
        if let closestCoordinate = polyline.closestCoordinate(to: location.coordinate) {
            let remainingDistance = polyline.distance(from: closestCoordinate.coordinate)
            let distanceTraveled = currentStep.distance - remainingDistance
            currentStepProgress.distanceTraveled = distanceTraveled
            NotificationCenter.default.post(name: .routeControllerProgressDidChange, object: self, userInfo: [
                RouteControllerNotificationUserInfoKey.routeProgressKey: routeProgress,
                RouteControllerNotificationUserInfoKey.locationKey: self.location!, //guaranteed value
                RouteControllerNotificationUserInfoKey.rawLocationKey: location //raw
                ])
        }
        
        updateDistanceToIntersection(from: location)
        updateRouteStepProgress(for: location)
        updateRouteLegProgress(for: location)
        
        guard userIsOnRoute(location) || !(delegate?.routeController?(self, shouldRerouteFrom: location) ?? true) else {
            reroute(from: location)
            return
        }
        
        updateSpokenInstructionProgress(for: location)

        // Check for faster route given users current location
        guard reroutesProactively else { return }
        // Only check for faster alternatives if the user has plenty of time left on the route.
        guard routeProgress.durationRemaining > 600 else { return }
        // If the user is approaching a maneuver, don't check for a faster alternatives
        guard routeProgress.currentLegProgress.currentStepProgress.durationRemaining > RouteControllerMediumAlertInterval else { return }
        checkForFasterRoute(from: location)
    }
    
    func updateIntersectionIndex(for currentStepProgress: RouteStepProgress) {
        let intersectionDistances = currentStepProgress.intersectionDistances
        let upcomingIntersectionIndex = intersectionDistances.index { $0 > currentStepProgress.distanceTraveled } ?? intersectionDistances.endIndex
        currentStepProgress.intersectionIndex = upcomingIntersectionIndex > 0 ? intersectionDistances.index(before: upcomingIntersectionIndex) : 0
    }
    
    func updateRouteLegProgress(for location: CLLocation) {
        let currentDestination = routeProgress.currentLeg.destination
        let legDurationRemaining = routeProgress.currentLegProgress.durationRemaining
        
        if legDurationRemaining < RouteControllerDurationRemainingWaypointArrival, currentDestination != previousArrivalWaypoint {
            previousArrivalWaypoint = currentDestination
            
            routeProgress.currentLegProgress.userHasArrivedAtWaypoint = true
            let advancesToNextLeg = delegate?.routeController?(self, didArriveAt: currentDestination) ?? true
            
            if !routeProgress.isFinalLeg && advancesToNextLeg {
                routeProgress.legIndex += 1
            }
        }
    }
    
    /**
     Monitors the user's course to see if it is consistantly moving away from what we expect the course to be at a given point.
     */
    func userCourseIsOnRoute(_ location: CLLocation) -> Bool {
        let nearByCoordinates = routeProgress.currentLegProgress.nearbyCoordinates
        guard let calculatedCourseForLocationOnStep = location.interpolatedCourse(along: nearByCoordinates) else { return true }
        
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
    
    /**
     Given a users current location, returns a Boolean whether they are currently on the route.

     If the user is not on the route, they should be rerouted.
     */
    @objc public func userIsOnRoute(_ location: CLLocation) -> Bool {

        // Find future location of user
        let metersInFrontOfUser = location.speed * RouteControllerDeadReckoningTimeInterval
        let locationInfrontOfUser = location.coordinate.coordinate(at: metersInFrontOfUser, facing: location.course)
        let newLocation = CLLocation(latitude: locationInfrontOfUser.latitude, longitude: locationInfrontOfUser.longitude)
        let radius = max(reroutingTolerance, location.horizontalAccuracy + RouteControllerUserLocationSnappingDistance)
        let isCloseToCurrentStep = newLocation.isWithin(radius, of: routeProgress.currentLegProgress.currentStep)
        
        guard !isCloseToCurrentStep || !userCourseIsOnRoute(location) else { return true }
        
        // Check and see if the user is near a future step.
        guard let nearestStep = routeProgress.currentLegProgress.closestStep(to: location.coordinate) else {
            return false
        }
        
        if nearestStep.distance < RouteControllerUserLocationSnappingDistance {
            advanceStepIndex(to: nearestStep.index)
            return true
        }
        
        return false
    }

    func checkForFasterRoute(from location: CLLocation) {
        guard let currentUpcomingManeuver = routeProgress.currentLegProgress.upComingStep else { return }

        guard let lastLocationDate = lastLocationDate else {
            self.lastLocationDate = location.timestamp
            return
        }

        // Only check every so often for a faster route.
        guard location.timestamp.timeIntervalSince(lastLocationDate) >= RouteControllerProactiveReroutingInterval else { return }
        let durationRemaining = routeProgress.durationRemaining

        getDirections(from: location) { [weak self] (route, error) in
            guard let strongSelf = self else { return }
            guard let route = route else { return }
            strongSelf.lastLocationDate = nil

            if let firstLeg = route.legs.first, let firstStep = firstLeg.steps.first,
                firstStep.expectedTravelTime >= RouteControllerMediumAlertInterval,
                currentUpcomingManeuver == firstLeg.steps[1],
                route.expectedTravelTime <= 0.9 * durationRemaining {
                strongSelf.didFindFasterRoute = true
                // If the upcoming maneuver in the new route is the same as the current upcoming maneuver, don't announce it
                strongSelf.routeProgress = RouteProgress(route: route, legIndex: 0, spokenInstructionIndex: strongSelf.routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex)
                strongSelf.delegate?.routeController?(strongSelf, didRerouteAlong: route)
                strongSelf.didReroute(notification: NSNotification(name: .routeControllerDidReroute, object: nil, userInfo: [
                    RouteControllerNotificationUserInfoKey.isProactiveKey: true
                ]))
                strongSelf.didFindFasterRoute = false
            }
        }
    }
    
    func reroute(from location: CLLocation) {
        if let lastRerouteLocation = lastRerouteLocation {
            guard location.distance(from: lastRerouteLocation) >= RouteControllerMaximumDistanceBeforeRecalculating else {
                return
            }
        }

        if isRerouting {
            return
        }

        isRerouting = true

        delegate?.routeController?(self, willRerouteFrom: location)
        NotificationCenter.default.post(name: .routeControllerWillReroute, object: self, userInfo: [
            RouteControllerNotificationUserInfoKey.locationKey: location
        ])

        self.lastRerouteLocation = location

        getDirections(from: location) { [weak self] (route, error) in
            guard let strongSelf = self else {
                return
            }

            if let error = error {
                strongSelf.delegate?.routeController?(strongSelf, didFailToRerouteWith: error)
                NotificationCenter.default.post(name: .routeControllerDidFailToReroute, object: self, userInfo: [
                    RouteControllerNotificationUserInfoKey.routingErrorKey: error
                ])
            }

            guard let route = route else { return }

            strongSelf.routeProgress = RouteProgress(route: route, legIndex: 0)
            strongSelf.routeProgress.currentLegProgress.stepIndex = 0
            strongSelf.delegate?.routeController?(strongSelf, didRerouteAlong: route)
        }
    }
    
    func checkForUpdates() {
        #if TARGET_IPHONE_SIMULATOR
            guard let version = Bundle(for: RouteController.self).object(forInfoDictionaryKey: "CFBundleShortVersionString") else { return }
            let latestVersion = String(describing: version)
            _ = URLSession.shared.dataTask(with: URL(string: "https://www.mapbox.com/mapbox-navigation-ios/latest_version")!, completionHandler: { (data, response, error) in
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

    func getDirections(from location: CLLocation, completion: @escaping (_ route: Route?, _ error: Error?)->Void) {
        routeTask?.cancel()

        let options = routeProgress.route.routeOptions
        options.waypoints = [Waypoint(coordinate: location.coordinate)] + routeProgress.remainingWaypoints
        if let firstWaypoint = options.waypoints.first, location.course >= 0 {
            firstWaypoint.heading = location.course
            firstWaypoint.headingAccuracy = 90
        }

        self.lastRerouteLocation = location

        if let accessToken = routeProgress.route.accessToken, let apiEndpoint = routeProgress.route.apiEndpoint, let host = apiEndpoint.host {
            directions = Directions(accessToken: accessToken, host: host)
        }

        routeTask = directions.calculate(options) { [weak self] (waypoints, routes, error) in
            defer {
                self?.isRerouting = false
            }
            if let error = error {
                return completion(nil, error)
            }
            
            guard let routes = routes else {
                return completion(nil, nil)
            }

            if let route = self?.mostSimilarRoute(in: routes) {
                return completion(route, error)
            } else if let route = routes.first {
                return completion(route, error)
            } else {
                return completion(nil, nil)
            }
        }
    }
    
    func mostSimilarRoute(in routes: [Route]) -> Route? {
        return routes.min { (left, right) -> Bool in
            let leftDistance = left.description.minimumEditDistance(to: routeProgress.route.description)
            let rightDistance = right.description.minimumEditDistance(to: routeProgress.route.description)
            return leftDistance < rightDistance
        }
    }

    func updateDistanceToIntersection(from location: CLLocation) {
        guard var intersections = routeProgress.currentLegProgress.currentStepProgress.step.intersections else { return }
        let currentStepProgress = routeProgress.currentLegProgress.currentStepProgress

        // The intersections array does not include the upcoming maneuver intersection.
        if let upcomingStep = routeProgress.currentLegProgress.upComingStep, let upcomingIntersection = upcomingStep.intersections, let firstUpcomingIntersection = upcomingIntersection.first {
            intersections += [firstUpcomingIntersection]
        }

        routeProgress.currentLegProgress.currentStepProgress.intersectionsIncludingUpcomingManeuverIntersection = intersections

        if let upcomingIntersection = routeProgress.currentLegProgress.currentStepProgress.upcomingIntersection {
            routeProgress.currentLegProgress.currentStepProgress.userDistanceToUpcomingIntersection = Polyline(currentStepProgress.step.coordinates!).distance(from: location.coordinate, to: upcomingIntersection.location)
        }
    }

    func updateRouteStepProgress(for location: CLLocation) {
        guard routeProgress.currentLegProgress.remainingSteps.count > 0 else { return }
        
        guard let userSnapToStepDistanceFromManeuver = userSnapToStepDistanceFromManeuver else { return }
        var courseMatchesManeuverFinalHeading = false

        // Bearings need to normalized so when the `finalHeading` is 359 and the user heading is 1,
        // we count this as within the `RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion`
        if let upcomingStep = routeProgress.currentLegProgress.upComingStep, let finalHeading = upcomingStep.finalHeading, let initialHeading = upcomingStep.initialHeading {
            let initialHeadingNormalized = initialHeading.wrap(min: 0, max: 360)
            let finalHeadingNormalized = finalHeading.wrap(min: 0, max: 360)
            let userHeadingNormalized = location.course.wrap(min: 0, max: 360)
            let expectedTurningAngle = initialHeadingNormalized.differenceBetween(finalHeadingNormalized)

            // If the upcoming maneuver is fairly straight,
            // do not check if the user is within x degrees of the exit heading.
            // For ramps, their current heading will very close to the exit heading.
            // We need to wait until their moving away from the maneuver location instead.
            // We can do this by looking at their snapped distance from the maneuver.
            // Once this distance is zero, they are at more moving away from the maneuver location
            if expectedTurningAngle <= RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion {
                courseMatchesManeuverFinalHeading = userSnapToStepDistanceFromManeuver == 0
            } else {
                courseMatchesManeuverFinalHeading = finalHeadingNormalized.differenceBetween(userHeadingNormalized) <= RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion
            }
        }

        let step = routeProgress.currentLegProgress.upComingStep?.maneuverLocation ?? routeProgress.currentLegProgress.currentStep.maneuverLocation
        let userAbsoluteDistance = step.distance(to: location.coordinate)
        let lastKnownUserAbsoluteDistance = routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation

        if userSnapToStepDistanceFromManeuver <= RouteControllerManeuverZoneRadius &&
            (courseMatchesManeuverFinalHeading || (userAbsoluteDistance > lastKnownUserAbsoluteDistance && lastKnownUserAbsoluteDistance > RouteControllerManeuverZoneRadius)) {
            advanceStepIndex()
        }

        routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation = userAbsoluteDistance
    }
    
    func updateSpokenInstructionProgress(for location: CLLocation) {
        guard let userSnapToStepDistanceFromManeuver = userSnapToStepDistanceFromManeuver else { return }
        guard let spokenInstructions = routeProgress.currentLegProgress.currentStepProgress.remainingSpokenInstructions else { return }
        
        for voiceInstruction in spokenInstructions {
            if userSnapToStepDistanceFromManeuver <= voiceInstruction.distanceAlongStep || routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex == 0 {
                
                NotificationCenter.default.post(name: .routeControllerDidPassSpokenInstructionPoint, object: self, userInfo: [
                    RouteControllerNotificationUserInfoKey.routeProgressKey: routeProgress
                ])

                routeProgress.currentLegProgress.currentStepProgress.spokenInstructionIndex += 1
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
    }
    
    func updateIntersectionDistances() {
        if let coordinates = routeProgress.currentLegProgress.currentStep.coordinates, let intersections = routeProgress.currentLegProgress.currentStep.intersections {
            let polyline = Polyline(coordinates)
            let distances = intersections.map { polyline.distance(from: coordinates.first, to: $0.location) }
            routeProgress.currentLegProgress.currentStepProgress.intersectionDistances = distances
        }
    }
}

struct SessionState {
    let identifier = UUID()
    var departureTimestamp: Date?
    var arrivalTimestamp: Date?

    var totalDistanceCompleted: CLLocationDistance = 0

    var numberOfReroutes = 0
    var lastRerouteDate: Date?

    var currentRoute: Route
    var originalRoute: Route
    
    var timeSpentInPortrait: TimeInterval = 0
    var timeSpentInLandscape: TimeInterval = 0
    
    var lastTimeInLandscape = Date()
    var lastTimeInPortrait = Date()
    
    var timeSpentInForeground: TimeInterval = 0
    var timeSpentInBackground: TimeInterval = 0
    
    var lastTimeInForeground = Date()
    var lastTimeInBackground = Date()

    var pastLocations = FixedLengthQueue<CLLocation>(length: 40)

    init(currentRoute: Route, originalRoute: Route) {
        self.currentRoute = currentRoute
        self.originalRoute = originalRoute
    }
}

// MARK: - Telemetry
extension RouteController {
    // MARK: Sending events
    func sendDepartEvent() {
        events.enqueueEvent(withName: MMEEventTypeNavigationDepart, attributes: events.navigationDepartEvent(routeController: self))
        events.flush()
    }

    func sendArriveEvent() {
        events.enqueueEvent(withName: MMEEventTypeNavigationArrive, attributes: events.navigationArriveEvent(routeController: self))
        events.flush()
    }

    open func sendCancelEvent(rating: Int? = nil, comment: String? = nil) {
        let attributes = events.navigationCancelEvent(routeController: self, rating: rating, comment: comment)
        events.enqueueEvent(withName: MMEEventTypeNavigationCancel, attributes: attributes)
        events.flush()
    }

    func sendFeedbackEvent(event: CoreFeedbackEvent) {
        // remove from outstanding event queue
        if let index = outstandingFeedbackEvents.index(of: event) {
            outstandingFeedbackEvents.remove(at: index)
        }

        let eventName = event.eventDictionary["event"] as! String
        let eventDictionary = events.navigationFeedbackEventWithLocationsAdded(event: event, routeController: self)

        events.enqueueEvent(withName: eventName, attributes: eventDictionary)
        events.flush()
    }

    // MARK: Enqueue feedback

    func enqueueFeedbackEvent(type: FeedbackType, description: String?) -> String {
        let eventDictionary = events.navigationFeedbackEvent(routeController: self, type: type, description: description)
        let event = FeedbackEvent(timestamp: Date(), eventDictionary: eventDictionary)

        outstandingFeedbackEvents.append(event)

        return event.id.uuidString
    }

    func enqueueRerouteEvent() -> String {
        let timestamp = Date()
        let eventDictionary = events.navigationRerouteEvent(routeController: self)

        sessionState.lastRerouteDate = timestamp
        sessionState.numberOfReroutes += 1

        let event = RerouteEvent(timestamp: Date(), eventDictionary: eventDictionary)

        outstandingFeedbackEvents.append(event)

        return event.id.uuidString
    }
    
    func enqueueFoundFasterRouteEvent() -> String {
        let timestamp = Date()
        let eventDictionary = events.navigationRerouteEvent(routeController: self, eventType: FasterRouteFoundEvent)
        
        sessionState.lastRerouteDate = timestamp
        
        let event = RerouteEvent(timestamp: Date(), eventDictionary: eventDictionary)
        
        outstandingFeedbackEvents.append(event)
        
        return event.id.uuidString
    }

    func checkAndSendOutstandingFeedbackEvents(forceAll: Bool) {
        let now = Date()
        let eventsToPush = forceAll ? outstandingFeedbackEvents : outstandingFeedbackEvents.filter {
            now.timeIntervalSince($0.timestamp) > SecondsBeforeCollectionAfterFeedbackEvent
        }
        for event in eventsToPush {
            sendFeedbackEvent(event: event)
        }
    }

    func resetSession() {
        sessionState = SessionState(currentRoute: routeProgress.route, originalRoute: routeProgress.route)
    }
}
