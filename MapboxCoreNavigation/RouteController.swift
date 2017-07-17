import Foundation
import CoreLocation
import MapboxDirections

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
    optional func routeController(_ routeController: RouteController, didUpdateLocations locations: [CLLocation])
}

/**
 A `RouteController` tracks the user’s progress along a route, posting notifications as the user reaches significant points along the route. On every location update, the route controller evaluates the user’s location, determining whether the user remains on the route. If not, the route controller calculates a new route.
 
 `RouteController` is responsible for the core navigation logic whereas 
 `NavigationViewController` is responsible for displaying a default drop-in navigation UI.
 */
@objc(MBRouteController)
open class RouteController: NSObject {
    
    var lastUserDistanceToStartOfRoute = Double.infinity
    
    var lastTimeStampSpentMovingAwayFromStart = Date()
    
    /**
     The route controller’s delegate.
     */
    public weak var delegate: RouteControllerDelegate?
    
    /**
     The Directions object used to create the route.
     */
    public let directions: Directions
    
    /**
     The route controller’s associated location manager.
     */
    public var locationManager: NavigationLocationManager! {
        didSet {
            oldValue?.delegate = nil
            locationManager.delegate = self
        }
    }
    
    /**
     If true, location updates will be simulated when driving through tunnels or other areas where there is none or bad GPS reception.
     */
    public var isDeadReckoningEnabled = false
    
    /**
     Details about the user’s progress along the current route, leg, and step.
     */
    public var routeProgress: RouteProgress {
        didSet {
            var userInfo = [String: Any]()
            if let location = locationManager.location {
                userInfo[MBRouteControllerNotificationLocationKey] = location
            }
            NotificationCenter.default.post(name: RouteControllerDidReroute, object: self, userInfo: userInfo)
        }
    }
    
    /**
     If true, the user puck is snapped to closest location on the route. 
     Defaults to false.
     */
    public var snapsUserLocationAnnotationToRoute = true
    
    var lastRerouteLocation: CLLocation?
    
    var routeTask: URLSessionDataTask?
    
    /**
     Intializes a new `RouteController`.
     
     - parameter route: The route to follow.
     - parameter directions: The Directions object that created `route`.
     - parameter locationManager: The associated location manager.
     */
    @objc(initWithRoute:directions:locationManager:)
    public init(along route: Route, directions: Directions = Directions.shared, locationManager: NavigationLocationManager = NavigationLocationManager()) {
        self.directions = directions
        self.routeProgress = RouteProgress(route: route)
        self.locationManager = locationManager
        self.locationManager.activityType = route.routeOptions.activityType
        super.init()
        
        self.locationManager.delegate = self
    }
    
    deinit {
        suspendLocationUpdates()
    }
    
    /**
     Starts monitoring the user’s location along the route.
     
     Will continue monitoring until `suspendLocationUpdates()` is called.
     */
    public func resume() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    /**
     Stops monitoring the user’s location along the route.
     */
    public func suspendLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
}

extension RouteController: CLLocationManagerDelegate {
    
    func interpolateLocation() {
        guard let location = locationManager.lastKnownLocation else { return }
        guard let polyline = routeProgress.route.coordinates else { return }
        
        let distance = location.speed as CLLocationDistance
        
        guard let interpolatedCoordinate = coordinate(at: routeProgress.distanceTraveled+distance, fromStartOf: polyline) else {
            return
        }
        
        var course = location.course
        if let upcomingCoordinate = coordinate(at: routeProgress.distanceTraveled+(distance*2), fromStartOf: polyline) {
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
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        delegate?.routeController?(self, didUpdateLocations: [location])
        
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(interpolateLocation), object: nil)
        
        if isDeadReckoningEnabled {
            perform(#selector(interpolateLocation), with: nil, afterDelay: 1.1)
        }
        
        let userSnapToStepDistanceFromManeuver = distance(along: routeProgress.currentLegProgress.currentStep.coordinates!, from: location.coordinate)
        let secondsToEndOfStep = userSnapToStepDistanceFromManeuver / location.speed
        
        guard routeProgress.currentLegProgress.alertUserLevel != .arrive else {
            NotificationCenter.default.post(name: RouteControllerProgressDidChange, object: self, userInfo: [
                RouteControllerProgressDidChangeNotificationProgressKey: routeProgress,
                RouteControllerProgressDidChangeNotificationLocationKey: location,
                RouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey: secondsToEndOfStep
                ])
            return
        }
        
        // Notify observers if the step’s remaining distance has changed.
        let currentStepProgress = routeProgress.currentLegProgress.currentStepProgress
        let currentStep = currentStepProgress.step
        if let closestCoordinate = closestCoordinate(on: currentStep.coordinates!, to: location.coordinate) {
            let remainingDistance = distance(along: currentStep.coordinates!, from: closestCoordinate.coordinate)
            let distanceTraveled = currentStep.distance - remainingDistance
            if distanceTraveled != currentStepProgress.distanceTraveled {
                currentStepProgress.distanceTraveled = distanceTraveled
                NotificationCenter.default.post(name: RouteControllerProgressDidChange, object: self, userInfo: [
                    RouteControllerProgressDidChangeNotificationProgressKey: routeProgress,
                    RouteControllerProgressDidChangeNotificationLocationKey: location,
                    RouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey: secondsToEndOfStep
                    ])
            }
        }
        
        let step = routeProgress.currentLegProgress.currentStepProgress.step
        if step.maneuverType == .depart && !userIsOnRoute(location) {
            
            guard let userSnappedDistanceToClosestCoordinate = closestCoordinate(on: step.coordinates!, to: location.coordinate)?.distance else {
                return
            }
            
            // Give the user x seconds of moving away from the start of the route before rerouting
            guard Date().timeIntervalSince(lastTimeStampSpentMovingAwayFromStart) > MaxSecondsSpentTravelingAwayFromStartOfRoute else {
                lastUserDistanceToStartOfRoute = userSnappedDistanceToClosestCoordinate
                return
            }
            
            // Don't check `userIsOnRoute` if the user has not moved
            guard userSnappedDistanceToClosestCoordinate != lastUserDistanceToStartOfRoute else {
                lastUserDistanceToStartOfRoute = userSnappedDistanceToClosestCoordinate
                return
            }
            
            if userSnappedDistanceToClosestCoordinate > lastUserDistanceToStartOfRoute {
                lastTimeStampSpentMovingAwayFromStart = location.timestamp
            }
            
            lastUserDistanceToStartOfRoute = userSnappedDistanceToClosestCoordinate
        }
        
        guard userIsOnRoute(location) || !(delegate?.routeController?(self, shouldRerouteFrom: location) ?? true) else {
            reroute(from: location)
            return
        }
        
        monitorStepProgress(location)
    }
    
    func resetStartCounter() {
        lastTimeStampSpentMovingAwayFromStart = Date()
        lastUserDistanceToStartOfRoute = Double.infinity
    }
    
    /**
     Given a users current location, returns a Boolean whether they are currently on the route.
     
     If the user is not on the route, they should be rerouted.
     */
    public func userIsOnRoute(_ location: CLLocation) -> Bool {
        // Find future location of user
        let metersInFrontOfUser = location.speed * RouteControllerDeadReckoningTimeInterval
        let locationInfrontOfUser = location.coordinate.coordinate(at: metersInFrontOfUser, facing: location.course)
        let newLocation = CLLocation(latitude: locationInfrontOfUser.latitude, longitude: locationInfrontOfUser.longitude)
        let radius = max(RouteControllerMaximumDistanceBeforeRecalculating,
                         location.horizontalAccuracy + RouteControllerUserLocationSnappingDistance)

        let isCloseToCurrentStep = newLocation.isWithin(radius, of: routeProgress.currentLegProgress.currentStep)
        
        // If the user is moving away from the maneuver location
        // and they are close to the next step
        // we can safely say they have completed the maneuver.
        // This is intended to be a fallback case when we do find
        // that the users course matches the exit bearing.
        if let upComingStep = routeProgress.currentLegProgress.upComingStep {
            let isCloseToUpComingStep = newLocation.isWithin(radius, of: upComingStep)
            if !isCloseToCurrentStep && isCloseToUpComingStep {
                let userSnapToStepDistanceFromManeuver = distance(along: upComingStep.coordinates!, from: location.coordinate)
                let secondsToEndOfStep = userSnapToStepDistanceFromManeuver / location.speed
                incrementRouteProgress(secondsToEndOfStep <= RouteControllerMediumAlertInterval ? .medium : .low, location: location, updateStepIndex: true)
                return true
            }
        }
        
        return isCloseToCurrentStep
    }
    
    func incrementRouteProgress(_ newlyCalculatedAlertLevel: AlertLevel, location: CLLocation, updateStepIndex: Bool) {
        
        if updateStepIndex {
            routeProgress.currentLegProgress.stepIndex += 1
        }
        
        // If the step is not being updated, don't accept a lower alert level.
        // A lower alert level can only occur when the user begins the next step.
        guard newlyCalculatedAlertLevel.rawValue > routeProgress.currentLegProgress.alertUserLevel.rawValue || updateStepIndex else {
            return
        }
        
        if routeProgress.currentLegProgress.alertUserLevel != newlyCalculatedAlertLevel {
            routeProgress.currentLegProgress.alertUserLevel = newlyCalculatedAlertLevel
            // Use fresh user location distance to end of step
            // since the step could of changed
            let userDistance = distance(along: routeProgress.currentLegProgress.currentStep.coordinates!, from: location.coordinate)
            
            NotificationCenter.default.post(name: RouteControllerAlertLevelDidChange, object: self, userInfo: [
                RouteControllerAlertLevelDidChangeNotificationRouteProgressKey: routeProgress,
                RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey: userDistance
                ])
        }
    }
    
    func reroute(from location: CLLocation) {
        
        if let lastRerouteLocation = lastRerouteLocation {
            guard location.distance(from: lastRerouteLocation) >= RouteControllerMaximumDistanceBeforeRecalculating else {
                return
            }
        }
        
        resetStartCounter()
        delegate?.routeController?(self, willRerouteFrom: location)
        NotificationCenter.default.post(name: RouteControllerWillReroute, object: self, userInfo: [
            MBRouteControllerNotificationLocationKey: location
            ])
        
        routeTask?.cancel()
        
        let options = routeProgress.route.routeOptions
        
        options.waypoints = [Waypoint(coordinate: location.coordinate)] + routeProgress.remainingWaypoints
        
        if let firstWaypoint = options.waypoints.first, location.course >= 0 {
            firstWaypoint.heading = location.course
            firstWaypoint.headingAccuracy = 90
        }
        
        self.lastRerouteLocation = location
        
        routeTask = directions.calculate(options, completionHandler: { [weak self] (waypoints, routes, error) in
            guard let strongSelf = self else {
                return
            }
            
            if let route = routes?.first {

                // If the first step of the new route is greater than 0.5km, let user continue without announcement.
                var alertLevel: AlertLevel = .none
                if let firstLeg = route.legs.first, let firstStep = firstLeg.steps.first, firstStep.distance > 500 {
                    alertLevel = .depart
                }
                strongSelf.routeProgress = RouteProgress(route: route, legIndex: 0, alertLevel: alertLevel)
                strongSelf.routeProgress.currentLegProgress.stepIndex = 0
                strongSelf.delegate?.routeController?(strongSelf, didRerouteAlong: route)
            } else if let error = error {
                strongSelf.delegate?.routeController?(strongSelf, didFailToRerouteWith: error)
                NotificationCenter.default.post(name: RouteControllerDidFailToReroute, object: self, userInfo: [
                    MBRouteControllerNotificationErrorKey: error
                    ])
            }
        })
    }
    
    func monitorStepProgress(_ location: CLLocation) {
        // Force an announcement when the user begins a route
        var alertLevel: AlertLevel = routeProgress.currentLegProgress.alertUserLevel == .none ? .depart : routeProgress.currentLegProgress.alertUserLevel
        var updateStepIndex = false
        let profileIdentifier = routeProgress.route.routeOptions.profileIdentifier
        
        let userSnapToStepDistanceFromManeuver = distance(along: routeProgress.currentLegProgress.currentStep.coordinates!, from: location.coordinate)
        let secondsToEndOfStep = userSnapToStepDistanceFromManeuver / location.speed
        var courseMatchesManeuverFinalHeading = false
        
        let minimumDistanceForHighAlert = RouteControllerMinimumDistanceForHighAlert(identifier: profileIdentifier)
        let minimumDistanceForMediumAlert = RouteControllerMinimumDistanceForMediumAlert(identifier: profileIdentifier)
        
        // Bearings need to normalized so when the `finalHeading` is 359 and the user heading is 1,
        // we count this as within the `RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion`
        if let upcomingStep = routeProgress.currentLegProgress.upComingStep, let finalHeading = upcomingStep.finalHeading, let initialHeading = upcomingStep.initialHeading {
            let initialHeadingNormalized = wrap(initialHeading, min: 0, max: 360)
            let finalHeadingNormalized = wrap(finalHeading, min: 0, max: 360)
            let userHeadingNormalized = wrap(location.course, min: 0, max: 360)
            let expectedTurningAngle = differenceBetweenAngles(initialHeadingNormalized, finalHeadingNormalized)
            
            // If the upcoming maneuver is fairly straight,
            // do not check if the user is within x degrees of the exit heading.
            // For ramps, their current heading will very close to the exit heading.
            // We need to wait until their moving away from the maneuver location instead.
            // We can do this by looking at their snapped distance from the maneuver.
            // Once this distance is zero, they are at more moving away from the maneuver location
            if expectedTurningAngle <= RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion {
                courseMatchesManeuverFinalHeading = userSnapToStepDistanceFromManeuver == 0
            } else {
                courseMatchesManeuverFinalHeading = differenceBetweenAngles(finalHeadingNormalized, userHeadingNormalized) <= RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion
            }
        }

        // When departing, `userSnapToStepDistanceFromManeuver` is most often less than `RouteControllerManeuverZoneRadius`
        // since the user will most often be at the beginning of the route, in the maneuver zone
        if alertLevel == .depart && userSnapToStepDistanceFromManeuver <= RouteControllerManeuverZoneRadius {
            // If the user is close to the maneuver location,
            // don't give a depature instruction.
            // Instead, give a `.high` alert.
            if secondsToEndOfStep <= RouteControllerHighAlertInterval {
                alertLevel = .high
            }
        } else if userSnapToStepDistanceFromManeuver <= RouteControllerManeuverZoneRadius {
            // Use the currentStep if there is not a next step
            // This occurs when arriving
            let step = routeProgress.currentLegProgress.upComingStep?.maneuverLocation ?? routeProgress.currentLegProgress.currentStep.maneuverLocation
            let userAbsoluteDistance = step - location.coordinate
            
            // userAbsoluteDistanceToManeuverLocation is set to nil by default
            // If it's set to nil, we know the user has never entered the maneuver radius
            if routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation == nil {
                routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation = RouteControllerManeuverZoneRadius
            }
            
            let lastKnownUserAbsoluteDistance = routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation
            
            // The objective here is to make sure the user is moving away from the maneuver location
            // This helps on maneuvers where the difference between the exit and enter heading are similar
            if  userAbsoluteDistance <= lastKnownUserAbsoluteDistance! {
                routeProgress.currentLegProgress.currentStepProgress.userDistanceToManeuverLocation = userAbsoluteDistance
            }
            
            if routeProgress.currentLegProgress.upComingStep?.maneuverType == ManeuverType.arrive {
                alertLevel = .arrive
            } else if courseMatchesManeuverFinalHeading {
                updateStepIndex = true
                
                // Look at the following step to determine what the new alert level should be
                if let upComingStep = routeProgress.currentLegProgress.upComingStep {
                    alertLevel = upComingStep.expectedTravelTime <= RouteControllerMediumAlertInterval ? .medium : .low
                } else {
                    assert(false, "In this case, there should always be an upcoming step")
                }
            }
        } else if secondsToEndOfStep <= RouteControllerHighAlertInterval && routeProgress.currentLegProgress.currentStep.distance > minimumDistanceForHighAlert {
            alertLevel = .high
        } else if secondsToEndOfStep <= RouteControllerMediumAlertInterval &&
            // Don't alert if the route segment is shorter than X
            // However, if it's the beginning of the route
            // There needs to be an alert
            routeProgress.currentLegProgress.currentStep.distance > minimumDistanceForMediumAlert {
            alertLevel = .medium
        }
        
        incrementRouteProgress(alertLevel, location: location, updateStepIndex: updateStepIndex)
    }
}
