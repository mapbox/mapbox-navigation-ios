import CoreLocation
import MapboxDirections
import Turf

extension CLLocation {
    
    var isQualified: Bool {
        return
            0...100 ~= horizontalAccuracy
    }
    
    /// Returns a dictionary representation of the location.
    public var dictionaryRepresentation: [String: Any] {
        var locationDictionary: [String: Any] = [:]
        locationDictionary["lat"] = coordinate.latitude
        locationDictionary["lng"] = coordinate.longitude
        locationDictionary["altitude"] = altitude
        locationDictionary["timestamp"] = timestamp.ISO8601
        locationDictionary["horizontalAccuracy"] = horizontalAccuracy
        locationDictionary["verticalAccuracy"] = verticalAccuracy
        locationDictionary["course"] = course
        locationDictionary["speed"] = speed
        return locationDictionary
    }
    
    /**
     Intializes a CLLocation from a dictionary.
     
     - parameter dictionary: A dictionary representation of the location.
     */
    public convenience init(dictionary: [String: Any]) {
        let latitude = dictionary["latitude"] as? CLLocationDegrees ?? dictionary["lat"] as? CLLocationDegrees ?? 0
        let longitude = dictionary["longitude"] as? CLLocationDegrees ?? dictionary["lon"] as? CLLocationDegrees ?? dictionary["lng"] as? CLLocationDegrees ?? 0
        let altitude = dictionary["altitude"] as! CLLocationDistance
        
        let horizontalAccuracy = dictionary["horizontalAccuracy"] as! CLLocationAccuracy
        let verticalAccuracy = dictionary["verticalAccuracy"] as! CLLocationAccuracy
        
        let speed = dictionary["speed"] as! CLLocationSpeed
        let course = dictionary["course"] as! CLLocationDirection
        
        var date: Date?
        
        // Parse timestamp as unix timestamp or ISO8601Date
        if let timestamp = dictionary["timestamp"] as? TimeInterval {
            date = Date(timeIntervalSince1970: timestamp)
        } else if let timestamp = dictionary["timestamp"] as? String {
            date = timestamp.ISO8601Date
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        self.init(coordinate: coordinate,
                  altitude: altitude,
                  horizontalAccuracy: horizontalAccuracy,
                  verticalAccuracy: verticalAccuracy,
                  course: course,
                  speed: speed,
                  timestamp: date!)
    }
    
    /**
     Returns a Boolean value indicating whether the receiver is within a given distance of a route step.
     */
    func isWithin(_ maximumDistance: CLLocationDistance, of routeStep: RouteStep) -> Bool {
        guard let closestCoordinate = Polyline(routeStep.coordinates!).closestCoordinate(to: coordinate) else {
            return false
        }
        return closestCoordinate.distance < maximumDistance
    }
    
    //MARK: - Route Snapping
    
    func snapped(to legProgress: RouteLegProgress) -> CLLocation? {
        let coords = coordinates(for: legProgress)
        
        guard let closest = Polyline(coords).closestCoordinate(to: coordinate) else { return nil }
        guard let calculatedCourseForLocationOnStep = interpolatedCourse(along: coords) else { return nil }
        
        let userCourse = calculatedCourseForLocationOnStep
        let userCoordinate = closest.coordinate
        guard let firstCoordinate = legProgress.leg.steps.first?.coordinates?.first else { return nil }
        
        guard shouldSnap(toRouteWith: calculatedCourseForLocationOnStep, distanceToFirstCoordinateOnLeg: self.coordinate.distance(to: firstCoordinate)) else { return nil }
        
        return CLLocation(coordinate: userCoordinate, altitude: altitude, horizontalAccuracy: horizontalAccuracy, verticalAccuracy: verticalAccuracy, course: userCourse, speed: speed, timestamp: timestamp)
    }
    
    /**
     Calculates the proper coordinates to use when calculating a snapped location.
     */
    func coordinates(for legProgress: RouteLegProgress) -> [CLLocationCoordinate2D] {
        let nearbyCoordinates = legProgress.nearbyCoordinates
        let stepCoordinates = legProgress.currentStep.coordinates!
        
        // If the upcoming maneuver a sharp turn, only look at the current step for snapping.
        // Otherwise, we may get false positives from nearby step coordinates
        if let upcomingStep = legProgress.upComingStep,
            let initialHeading = upcomingStep.initialHeading,
            let finalHeading = upcomingStep.finalHeading {
            
            // The max here is 180. The closer it is to 180, the sharper the turn.
            if initialHeading.clockwiseDifference(from: finalHeading) > 180 - RouteSnappingMaxManipulatedCourseAngle {
                return stepCoordinates
            }
            
            
            if finalHeading.difference(from: course) > RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion {
                return stepCoordinates
            }
        }
        
        if speed <= RouteControllerMaximumSpeedForUsingCurrentStep {
            return stepCoordinates
        }
        
        return nearbyCoordinates
    }
    
    
    /**
     Given a location and a series of coordinates, compute what the course should be for a the location.
     */
    func interpolatedCourse(along coordinates: [CLLocationCoordinate2D]) -> CLLocationDirection? {
        let nearByPolyline = Polyline(coordinates)
        
        guard let closest = nearByPolyline.closestCoordinate(to: coordinate) else { return nil }
        
        let slicedLineBehind = Polyline(coordinates.reversed()).sliced(from: closest.coordinate, to: coordinates.reversed().last)
        let slicedLineInFront = nearByPolyline.sliced(from: closest.coordinate, to: coordinates.last)
        let userDistanceBuffer: CLLocationDistance = max(speed * RouteControllerDeadReckoningTimeInterval / 2, RouteControllerUserLocationSnappingDistance / 2)
        
        guard let pointBehind = slicedLineBehind.coordinateFromStart(distance: userDistanceBuffer) else { return nil }
        guard let pointBehindClosest = nearByPolyline.closestCoordinate(to: pointBehind) else { return nil }
        guard let pointAhead = slicedLineInFront.coordinateFromStart(distance: userDistanceBuffer) else { return nil }
        guard let pointAheadClosest = nearByPolyline.closestCoordinate(to: pointAhead) else { return nil }
        
        // Get direction of these points
        let pointBehindDirection = pointBehindClosest.coordinate.direction(to: closest.coordinate)
        let pointAheadDirection = closest.coordinate.direction(to: pointAheadClosest.coordinate)
        let wrappedPointBehind = pointBehindDirection.wrap(min: -180, max: 180)
        let wrappedPointAhead = pointAheadDirection.wrap(min: -180, max: 180)
        let wrappedCourse = course.wrap(min: -180, max: 180)
        let relativeAnglepointBehind = (wrappedPointBehind - wrappedCourse).wrap(min: -180, max: 180)
        let relativeAnglepointAhead = (wrappedPointAhead - wrappedCourse).wrap(min: -180, max: 180)
        
        let averageRelativeAngle: Double
        // User is at the beginning of the route, there is no closest point behind the user.
        if pointBehindClosest.distance <= 0 && pointAheadClosest.distance > 0 {
            averageRelativeAngle = relativeAnglepointAhead
            // User is at the end of the route, there is no closest point in front of the user.
        } else if pointAheadClosest.distance <= 0 && pointBehindClosest.distance > 0 {
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

        if course >= 0 &&
            (speed >= RouteSnappingMinimumSpeed || isWithinDepatureStep) &&
            (horizontalAccuracy < RouteSnappingMinimumHorizontalAccuracy || isWithinDepatureStep) &&
            course.difference(from: self.course) > RouteSnappingMaxManipulatedCourseAngle {
            return false
        }
        return true
    }
}
