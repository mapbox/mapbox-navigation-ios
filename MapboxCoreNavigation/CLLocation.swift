import Foundation
import CoreLocation
import MapboxDirections

public extension CLLocation {
    /**
     Returns a `CLLocation` infront of the provided location given the interval
     with the current speed taken into account.
     */
    public func advanced(by interval: TimeInterval) -> CLLocation {
        let metersAhead = speed * interval
        let locationInfrontOfUser = coordinate.coordinate(at: metersAhead, facing: course)
        return CLLocation(coordinate: locationInfrontOfUser.coordinate(at: metersAhead, facing: course),
                          altitude: altitude,
                          horizontalAccuracy: horizontalAccuracy,
                          verticalAccuracy: verticalAccuracy,
                          course: course,
                          speed: speed,
                          timestamp: timestamp.addingTimeInterval(interval))
    }
    
    public func isOnRoute(with routeProgress: RouteProgress) -> Bool {
        let newLocation = advanced(by: RouteControllerDeadReckoningTimeInterval)
        let isCloseToCurrentStep = newLocation.isWithin(rerouteRadius, of: routeProgress.currentLegProgress.currentStep)
        
        // If the user is moving away from the maneuver location
        // and they are close to the next step
        // we can safely say they have completed the maneuver.
        // This is intended to be a fallback case when we do find
        // that the users course matches the exit bearing.
        if let upComingStep = routeProgress.currentLegProgress.upComingStep {
            let isCloseToUpComingStep = newLocation.isWithin(rerouteRadius, of: upComingStep)
            if !isCloseToCurrentStep && isCloseToUpComingStep {
                return !isCloseToCurrentStep && isCloseToUpComingStep
            }
        }
        
        return isCloseToCurrentStep
    }
    
    /**
     Returns the maximum reroute radius
     */
    public static func radiusForRerouting(with horizontalAccuracy: CLLocationAccuracy) -> CLLocationDistance {
        return max(RouteControllerMaximumDistanceBeforeRecalculating, horizontalAccuracy + RouteControllerUserLocationSnappingDistance)
    }
    
    /**
     Returns the maximum reroute radius
     */
    public var rerouteRadius: CLLocationDistance {
        return CLLocation.radiusForRerouting(with: horizontalAccuracy)
    }
}
