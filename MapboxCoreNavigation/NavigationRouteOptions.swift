import Foundation
import MapboxDirections

/**
 A `NavigationRouteOptions` object specifies turn-by-turn-optimized criteria for results returned by the Mapbox Directions API.

 `NavigationRouteOptions` is a subclass of `RouteOptions` that has been optimized for navigation. Pass an instance of this class into the `Directions.calculate(_:completionHandler:)` method.
 - note: `NavigationRouteOptions` is designed to be used with the `Directions` and `NavigationDirections` classes for specifying routing criteria. To customize the user experience in a `NavigationViewController`, use the `NavigationOptions` class.
 */
open class NavigationRouteOptions: RouteOptions {
    /**
     Initializes a navigation route options object for routes between the given waypoints and an optional profile identifier optimized for navigation.

     - seealso: `RouteOptions`
     */
    public required init(waypoints: [Waypoint], profileIdentifier: DirectionsProfileIdentifier? = .cycling) {
        super.init(waypoints: waypoints.map {
            $0.coordinateAccuracy = -1
            return $0
        }, profileIdentifier: profileIdentifier)
        includesAlternativeRoutes = false
        shapeFormat = .polyline6
        includesSteps = true
        routeShapeResolution = .full
        if profileIdentifier == .walking {
            attributeOptions = [.congestionLevel, .expectedTravelTime]
        } else {
            attributeOptions = [.congestionLevel, .expectedTravelTime, .maximumSpeedLimit]
        }
        includesSpokenInstructions = false
        locale = Locale.nationalizedCurrent
        distanceMeasurementSystem = Locale.current.usesMetricSystem ? .metric : .imperial
        includesVisualInstructions = true
        includesExitRoundaboutManeuver = true
    }

    /**
     Initializes a navigation route options object for routes between the given locations and an optional profile identifier optimized for navigation.

     - seealso: `RouteOptions`
     */
    public convenience init(locations: [CLLocation], profileIdentifier: DirectionsProfileIdentifier? = .automobileAvoidingTraffic) {
        self.init(waypoints: locations.map { Waypoint(location: $0) }, profileIdentifier: profileIdentifier)
    }

    /**
     Initializes a route options object for routes between the given geographic coordinates and an optional profile identifier optimized for navigation.

     - seealso: `RouteOptions`
     */
    public convenience init(coordinates: [CLLocationCoordinate2D], profileIdentifier: DirectionsProfileIdentifier? = .automobileAvoidingTraffic) {
        self.init(waypoints: coordinates.map { Waypoint(coordinate: $0) }, profileIdentifier: profileIdentifier)
    }
    
    required public init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

/**
 A `NavigationMatchOptions` object specifies turn-by-turn-optimized criteria for results returned by the Mapbox Map Matching API.
 
 `NavigationMatchOptions` is a subclass of `MatchOptions` that has been optimized for navigation. Pass an instance of this class into the `Directions.calculateRoutes(matching:completionHandler:).` method.
 
 Note: it is very important you specify the `waypoints` for the route. Usually the only two values for this `IndexSet` will be 0 and the length of the coordinates. Otherwise, all coordinates passed through will be considered waypoints.
 */
open class NavigationMatchOptions: MatchOptions {
    /**
     Initializes a navigation route options object for routes between the given waypoints and an optional profile identifier optimized for navigation.
     
     - seealso: `MatchOptions`
     */
    public required init(waypoints: [Waypoint], profileIdentifier: DirectionsProfileIdentifier? = .automobileAvoidingTraffic) {
        super.init(waypoints: waypoints.map {
            $0.coordinateAccuracy = -1
            return $0
        }, profileIdentifier: profileIdentifier)
        includesSteps = true
        routeShapeResolution = .full
        shapeFormat = .polyline6
        attributeOptions = [.congestionLevel, .expectedTravelTime]
        if profileIdentifier == .automobile || profileIdentifier == .automobileAvoidingTraffic {
            attributeOptions.insert(.maximumSpeedLimit)
        }
        includesSpokenInstructions = true
        locale = Locale.nationalizedCurrent
        distanceMeasurementSystem = Locale.current.usesMetricSystem ? .metric : .imperial
        includesVisualInstructions = true
    }
    
    /**
     Initializes a navigation match options object for routes between the given locations and an optional profile identifier optimized for navigation.
     
     - seealso: `MatchOptions`
     */
    public convenience init(locations: [CLLocation], profileIdentifier: DirectionsProfileIdentifier? = .automobileAvoidingTraffic) {
        self.init(waypoints: locations.map { Waypoint(location: $0) }, profileIdentifier: profileIdentifier)
    }
    
    /**
     Initializes a navigation match options object for routes between the given geographic coordinates and an optional profile identifier optimized for navigation.
     
     - seealso: `MatchOptions`
     */
    public convenience init(coordinates: [CLLocationCoordinate2D], profileIdentifier: DirectionsProfileIdentifier? = .automobileAvoidingTraffic) {
        self.init(waypoints: coordinates.map { Waypoint(coordinate: $0) }, profileIdentifier: profileIdentifier)
    }
    
    required public init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
