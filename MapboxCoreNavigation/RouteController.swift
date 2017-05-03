import Foundation
import CoreLocation
import MapboxDirections

/*
 RouteController helps user navigate along a route.
 */

@objc(MBRouteController)
open class RouteController: NSObject {
    
    var lastUserDistanceToStartOfRoute = Double.infinity
    
    var lastTimeStampSpentMovingAwayFromStart = Date()
    
    /*
     Monitor users location along route.

     The variable can be provided by the developer so options on it can be set.
    */
    public var locationManager = CLLocationManager()
    
    
    /*
     `routeProgress` is a class containing all progress information of user along the route, leg and step.
    */
    public var routeProgress: RouteProgress
    
    
    /*
     If true, the user puck is snapped to closest location on the route.
    */
    public var snapsUserLocationAnnotationToRoute = false
    
    public var simulatesLocationUpdates: Bool = false {
        didSet {
            locationManager.delegate = simulatesLocationUpdates ? nil : self
        }
    }
    
    /*
     Intializes a new `RouteController`.
     
     - parameter Route: A `Route` object representing the users route it will follow.
     */
    public init(route: Route) {
        self.routeProgress = RouteProgress(route: route)
        super.init()
        
        locationManager.delegate = self
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    deinit {
        suspendLocationUpdates()
    }
    
    /*
     Starts monitoring user location along route.
     
     Will continue monitoring until `suspend()` is called.
     */
    public func resume() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    /*
     Stops monitoring users location along route.
     */
    public func suspendLocationUpdates() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
}

extension RouteController: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        
        let userSnapToStepDistanceFromManeuver = distance(along: routeProgress.currentLegProgress.currentStep.coordinates!, from: location.coordinate)
        let secondsToEndOfStep = userSnapToStepDistanceFromManeuver / location.speed
        
        guard routeProgress.currentLegProgress.alertUserLevel != .arrive else {
            // Don't advance nor check progress if the user has arrived at their destination
            suspendLocationUpdates()
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
        
        guard userIsOnRoute(location) else {
            resetStartCounter()
            NotificationCenter.default.post(name: RouteControllerShouldReroute, object: self, userInfo: [
                RouteControllerNotificationShouldRerouteKey: location
                ])
            return
        }
        
        monitorStepProgress(location)
    }
    
    func resetStartCounter() {
        lastTimeStampSpentMovingAwayFromStart = Date()
        lastUserDistanceToStartOfRoute = Double.infinity
    }
    
    public func userIsOnRoute(_ location: CLLocation) -> Bool {
        // Find future location of user
        let metersInFrontOfUser = location.speed * RouteControllerDeadReckoningTimeInterval
        let locationInfrontOfUser = location.coordinate.coordinate(at: metersInFrontOfUser, facing: location.course)
        let newLocation = CLLocation(latitude: locationInfrontOfUser.latitude, longitude: locationInfrontOfUser.longitude)
        let radius = min(RouteControllerMaximumDistanceBeforeRecalculating,
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
                
                // Increment the step
                routeProgress.currentLegProgress.stepIndex += 1
                
                // and reset the alert level since we're on the next step
                let userSnapToStepDistanceFromManeuver = distance(along: routeProgress.currentLegProgress.currentStep.coordinates!, from: location.coordinate)
                let secondsToEndOfStep = userSnapToStepDistanceFromManeuver / location.speed
                incrementRouteProgressAlertLevel(secondsToEndOfStep <= RouteControllerMediumAlertInterval ? .medium : .low, location: location)
                return true
            }
        }
        
        return isCloseToCurrentStep
    }
    
    func incrementRouteProgressAlertLevel(_ newlyCalculatedAlertLevel: AlertLevel, location: CLLocation) {
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
    
    func monitorStepProgress(_ location: CLLocation) {
        // Force an announcement when the user begins a route
        var alertLevel: AlertLevel = routeProgress.currentLegProgress.alertUserLevel == .none ? .depart : routeProgress.currentLegProgress.alertUserLevel
        let profileIdentifier = routeProgress.route.routeOptions.profileIdentifier
        
        let userSnapToStepDistanceFromManeuver = distance(along: routeProgress.currentLegProgress.currentStep.coordinates!, from: location.coordinate)
        let secondsToEndOfStep = userSnapToStepDistanceFromManeuver / location.speed
        var courseMatchesManeuverFinalHeading = false
        
        let minimumDistanceForHighAlert = RouteControllerMinimumDistanceForHighAlert(identifier: profileIdentifier)
        let minimumDistanceForMediumAlert = RouteControllerMinimumDistanceForMediumAlert(identifier: profileIdentifier)
        
        // Bearings need to normalized so when the `finalHeading` is 359 and the user heading is 1,
        // we count this as within the `RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion`
        if let finalHeading = routeProgress.currentLegProgress.upComingStep?.finalHeading {
            let finalHeadingNormalized = wrap(finalHeading, min: 0, max: 360)
            let userHeadingNormalized = wrap(location.course, min: 0, max: 360)
            courseMatchesManeuverFinalHeading = differenceBetweenAngles(finalHeadingNormalized, userHeadingNormalized) <= RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion
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
                routeProgress.currentLegProgress.stepIndex += 1
                let userSnapToStepDistanceFromManeuver = distance(along: routeProgress.currentLegProgress.currentStep.coordinates!, from: location.coordinate)
                let secondsToEndOfStep = userSnapToStepDistanceFromManeuver / location.speed
                alertLevel = secondsToEndOfStep <= RouteControllerMediumAlertInterval ? .medium : .low
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
        
        incrementRouteProgressAlertLevel(alertLevel, location: location)
    }
}
