import CoreLocation
import MapboxDirections
import MapboxNavigationNative
import Turf

extension CLLocation {
    convenience init(_ location: FixLocation) {
        if #available(iOS 13.4, *) {
            self.init(coordinate: location.coordinate,
                      altitude: location.altitude?.doubleValue ?? 0,
                      horizontalAccuracy: location.accuracyHorizontal?.doubleValue ?? -1,
                      verticalAccuracy: location.verticalAccuracy?.doubleValue ?? -1,
                      course: location.bearing?.doubleValue ?? -1,
                      courseAccuracy: location.bearingAccuracy?.doubleValue ?? -1,
                      speed: location.speed?.doubleValue ?? -1,
                      speedAccuracy: location.speedAccuracy?.doubleValue ?? -1,
                      timestamp: location.time)
        } else {
            self.init(coordinate: location.coordinate,
                      altitude: location.altitude?.doubleValue ?? 0,
                      horizontalAccuracy: location.accuracyHorizontal?.doubleValue ?? -1,
                      verticalAccuracy: location.verticalAccuracy?.doubleValue ?? -1,
                      course: location.bearing?.doubleValue ?? -1,
                      speed: location.speed?.doubleValue ?? -1,
                      timestamp: location.time)
        }
    }
    
    var isQualified: Bool {
        return 0...100 ~= horizontalAccuracy
    }
    
    var isQualifiedForStartingRoute: Bool {
        return 0...20 ~= horizontalAccuracy
    }
    
    /**
     Returns a Boolean value indicating whether the receiver is within a given distance of a route step.
     */
    func isWithin(_ maximumDistance: CLLocationDistance, of routeStep: RouteStep) -> Bool {
        guard let shape = routeStep.shape, let closestCoordinate = shape.closestCoordinate(to: coordinate) else {
            return false
        }
        return closestCoordinate.coordinate.distance(to: coordinate) < maximumDistance
    }
    
    //MARK: - Route Snapping
    
    func snapped(to routeProgress: RouteProgress) -> CLLocation? {
        let legProgress = routeProgress.currentLegProgress
        let polyline = snappingPolyline(for: routeProgress)
        
        guard let closest = polyline.closestCoordinate(to: coordinate) else { return nil }
        guard let calculatedCourseForLocationOnStep = interpolatedCourse(along: polyline) else { return nil }
        
        let userCourse = calculatedCourseForLocationOnStep
        let userCoordinate = closest.coordinate
        guard let firstCoordinate = legProgress.leg.steps.first?.shape?.coordinates.first else { return nil }
        
        guard shouldSnap(toRouteWith: calculatedCourseForLocationOnStep, distanceToFirstCoordinateOnLeg: self.coordinate.distance(to: firstCoordinate)) else { return nil }
        
        return CLLocation(coordinate: userCoordinate, altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: userCourse, speed: speed, timestamp: timestamp)
    }
    
    /**
     Calculates the proper coordinates to use when calculating a snapped location.
     */
    func snappingPolyline(for routeProgress: RouteProgress) -> LineString {
        let legProgress = routeProgress.currentLegProgress
        let nearbyPolyline = routeProgress.nearbyShape
        let stepPolyline = legProgress.currentStep.shape!
        
        // If the upcoming maneuver a sharp turn, only look at the current step for snapping.
        // Otherwise, we may get false positives from nearby step coordinates
        if let upcomingStep = legProgress.upcomingStep,
            let initialHeading = upcomingStep.initialHeading,
            let finalHeading = upcomingStep.finalHeading {
            // The max here is 180. The closer it is to 180, the sharper the turn.
            if initialHeading.clockwiseDifference(from: finalHeading) > 180 - RouteSnappingMaxManipulatedCourseAngle {
                return stepPolyline
            }
            
            if finalHeading.difference(from: course) > RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion {
                return stepPolyline
            }
        }
        
        if speed <= RouteControllerMaximumSpeedForUsingCurrentStep {
            return stepPolyline
        }
        
        return nearbyPolyline
    }
    
    /**
     Given a location and a series of coordinates, compute what the course should be for a the location.
     */
    func interpolatedCourse(along polyline: LineString) -> CLLocationDirection? {
        guard let closest = polyline.closestCoordinate(to: coordinate) else { return nil }
        
        let reversedPolyline = LineString(polyline.coordinates.reversed())
        let slicedLineBehind = reversedPolyline.sliced(from: closest.coordinate, to: reversedPolyline.coordinates.last)!
        let slicedLineInFront = polyline.sliced(from: closest.coordinate, to: polyline.coordinates.last)!
        let userDistanceBuffer: CLLocationDistance = max(speed * RouteControllerDeadReckoningTimeInterval / 2, RouteControllerUserLocationSnappingDistance / 2)
        
        guard let pointBehind = slicedLineBehind.coordinateFromStart(distance: userDistanceBuffer) else { return nil }
        guard let pointBehindClosest = polyline.closestCoordinate(to: pointBehind) else { return nil }
        guard let pointAhead = slicedLineInFront.coordinateFromStart(distance: userDistanceBuffer) else { return nil }
        guard let pointAheadClosest = polyline.closestCoordinate(to: pointAhead) else { return nil }
        
        // Get direction of these points
        let pointBehindDirection = pointBehindClosest.coordinate.direction(to: closest.coordinate)
        let pointAheadDirection = closest.coordinate.direction(to: pointAheadClosest.coordinate)
        let wrappedPointBehind = pointBehindDirection.wrap(min: -180, max: 180)
        let wrappedPointAhead = pointAheadDirection.wrap(min: -180, max: 180)
        let wrappedCourse = course.wrap(min: -180, max: 180)
        let relativeAnglepointBehind = (wrappedPointBehind - wrappedCourse).wrap(min: -180, max: 180)
        let relativeAnglepointAhead = (wrappedPointAhead - wrappedCourse).wrap(min: -180, max: 180)
        
        let distanceBehindClosest = pointBehindClosest.coordinate.distance(to: pointBehind)
        let distanceAheadClosest = pointAheadClosest.coordinate.distance(to: pointAhead)
        
        let averageRelativeAngle: Double
        // User is at the beginning of the route, there is no closest point behind the user.
        if distanceBehindClosest <= 0 && distanceAheadClosest > 0 {
            averageRelativeAngle = relativeAnglepointAhead
            // User is at the end of the route, there is no closest point in front of the user.
        } else if distanceAheadClosest <= 0 && distanceBehindClosest > 0 {
            averageRelativeAngle = relativeAnglepointBehind
        } else {
            averageRelativeAngle = (relativeAnglepointBehind + relativeAnglepointAhead) / 2
        }
        
        return (wrappedCourse + averageRelativeAngle).wrap(min: 0, max: 360)
    }
    
    /**
     Determines if the a location is qualified enough to allow the user puck to become unsnapped.
     */
    func shouldSnap(toRouteWith course: CLLocationDirection, distanceToFirstCoordinateOnLeg: CLLocationDistance = CLLocationDistanceMax) -> Bool {
        // If the user is near the beginning of leg, allow for unsnapped more often.
        let isWithinDepatureStep = distanceToFirstCoordinateOnLeg < RouteControllerManeuverZoneRadius

        if course.isQualified &&
            (speed >= RouteSnappingMinimumSpeed || isWithinDepatureStep) &&
            (horizontalAccuracy < RouteSnappingMinimumHorizontalAccuracy || isWithinDepatureStep) &&
            self.course.isQualified && course.difference(from: self.course) > RouteSnappingMaxManipulatedCourseAngle {
            return false
        }
        return true
    }
    
    func shifted(to newTimestamp: Date) -> CLLocation {
        return CLLocation(coordinate: coordinate, altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: course, speed: speed, timestamp: newTimestamp)
    }
}
