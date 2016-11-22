import Foundation
import CoreLocation
import MapboxDirections

@objc(MBRouteController)
open class RouteController: NSObject {
    public var locationManager = CLLocationManager()
    public var routeProgress: RouteProgress
    
    public init(route: Route) {
        self.routeProgress = RouteProgress(route: route)
        super.init()
        
        locationManager.delegate = self
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    deinit {
        suspend()
    }
    
    public func resume() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    public func suspend() {
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
            suspend()
            NotificationCenter.default.post(name: RouteControllerProgressDidChange, object: self, userInfo: [
                RouteControllerProgressDidChangeNotificationProgressKey: routeProgress,
                RouteControllerProgressDidChangeNotificationLocationKey: location,
                RouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey: secondsToEndOfStep
                ])
            return
        }
        
        guard userIsOnRoute(location) else {
            NotificationCenter.default.post(name: RouteControllerShouldReroute, object: self, userInfo: nil)
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
        
        monitorStepProgress(location)
    }
    
    func userIsOnRoute(_ location: CLLocation) -> Bool {
        // Find future location of user
        let metersInFrontOfUser = location.speed * RouteControllerDeadReckoningTimeInterval
        let locationInfrontOfUser = location.coordinate.coordinate(at: metersInFrontOfUser, facing: location.course)
        let newLocation = CLLocation(latitude: locationInfrontOfUser.latitude, longitude: locationInfrontOfUser.longitude)
        return newLocation.isWithin(RouteControllerMaximumMetersBeforeRecalculating, of: routeProgress.currentLegProgress.currentStep)
    }
    
    func sendVoiceAlert(distance: CLLocationDistance, isFirstAlertForStep: Bool? = false) {
        NotificationCenter.default.post(name: RouteControllerAlertLevelDidChange, object: self, userInfo: [
            RouteControllerAlertLevelDidChangeNotificationRouteProgressKey: routeProgress,
            RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey: distance,
            RouteControllerProgressDidChangeNotificationIsFirstAlertForStepKey: isFirstAlertForStep
            ])
    }

    
    func monitorStepProgress(_ location: CLLocation) {
        // Force an announcement when the user begins a route
        var alertLevel: AlertLevel = routeProgress.currentLegProgress.alertUserLevel == .none ? .depart : routeProgress.currentLegProgress.alertUserLevel
        
        let userSnapToStepDistanceFromManeuver = distance(along: routeProgress.currentLegProgress.currentStep.coordinates!, from: location.coordinate)
        let secondsToEndOfStep = userSnapToStepDistanceFromManeuver / location.speed
        var courseMatchesManeuverFinalHeading = false
        var isFirstAlertForStep = false
        
        // Bearings need to normalized so when the `finalHeading` is 359 and the user heading is 1,
        // we count this as within the `RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion`
        if let finalHeading = routeProgress.currentLegProgress.upComingStep?.finalHeading {
            let finalHeadingNormalized = wrap(finalHeading, min: 0, max: 360)
            let userHeadingNormalized = wrap(location.course, min: 0, max: 360)
            courseMatchesManeuverFinalHeading = abs(finalHeadingNormalized - userHeadingNormalized) <= RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion
        }
        
        if userSnapToStepDistanceFromManeuver <= RouteControllerManeuverZoneRadius {
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
                isFirstAlertForStep = true
            }
        } else if secondsToEndOfStep <= RouteControllerHighAlertInterval && routeProgress.currentLegProgress.currentStep.distance > RouteControllerMinimumDistanceForHighAlert {
            alertLevel = .high
        } else if secondsToEndOfStep <= RouteControllerMediumAlertInterval &&
            // Don't alert if the route segment is shorter than X
            // However, if it's the beginning of the route
            // There needs to be an alert
            routeProgress.currentLegProgress.currentStep.distance > RouteControllerMinimumDistanceForMediumAlert {
            alertLevel = .medium
        }
        
        if routeProgress.currentLegProgress.alertUserLevel != alertLevel {
            routeProgress.currentLegProgress.alertUserLevel = alertLevel
            // Use fresh user location distance to end of step
            // since the step could of changed
            sendVoiceAlert(distance: distance(along: routeProgress.currentLegProgress.currentStep.coordinates!, from: location.coordinate), isFirstAlertForStep: isFirstAlertForStep)
        }
    }
}
