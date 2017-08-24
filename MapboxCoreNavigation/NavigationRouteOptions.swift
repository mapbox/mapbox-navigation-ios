import Foundation
import MapboxDirections

/**
 A NavigationRouteOptions object specifies turn-by-turn-optimized criteria for results returned by the Mapbox Directions API.
 
 `NavigationRouteOptions` is a subclass of `RouteOptions` that has been optimized for navigation. Pass an instance of this class into the `Directions.calculate(_:completionHandler:)` method.
 */
@objc(MBNavigationRouteOptions)
open class NavigationRouteOptions: RouteOptions {
    
    /**
     Initializes a navigation route options object for routes between the given waypoints and an optional profile identifier optimized for navigation.
     
     - parameter waypoints: An array of `Waypoint` objects representing locations that the route should visit in chronological order. The array should contain at least two waypoints (the source and destination) and at most 25 waypoints. (Some profiles, such as `MBDirectionsProfileIdentifierAutomobileAvoidingTraffic`, [may have lower limits](https://www.mapbox.com/api-documentation/#directions).)
     - parameter profileIdentifier: A string specifying the primary mode of transportation for the routes. This parameter, if set, should be set to `MBDirectionsProfileIdentifierAutomobile`, `MBDirectionsProfileIdentifierAutomobileAvoidingTraffic`, `MBDirectionsProfileIdentifierCycling`, or `MBDirectionsProfileIdentifierWalking`. `MBDirectionsProfileIdentifierAutomobile` is used by default.
     */
    public override init(waypoints: [Waypoint], profileIdentifier: MBDirectionsProfileIdentifier? = .automobileAvoidingTraffic) {
        super.init(waypoints: waypoints, profileIdentifier: profileIdentifier)
        includesSteps = true
        routeShapeResolution = .full
        attributeOptions = [.congestionLevel, .expectedTravelTime]
    }
    
    
    /**
     Initializes a navigation route options object for routes between the given locations and an optional profile identifier optimized for navigation.
     
     - note: This initializer is intended for `CLLocation` objects created using the `CLLocation.init(latitude:longitude:)` initializer. If you intend to use a `CLLocation` object obtained from a `CLLocationManager` object, consider increasing the `horizontalAccuracy` or set it to a negative value to avoid overfitting, since the `Waypoint` class’s `coordinateAccuracy` property represents the maximum allowed deviation from the waypoint.
     
     - parameter locations: An array of `CLLocation` objects representing locations that the route should visit in chronological order. The array should contain at least two locations (the source and destination) and at most 25 locations. Each location object is converted into a `Waypoint` object. This class respects the `CLLocation` class’s `coordinate` and `horizontalAccuracy` properties, converting them into the `Waypoint` class’s `coordinate` and `coordinateAccuracy` properties, respectively.
     - parameter profileIdentifier: A string specifying the primary mode of transportation for the routes. This parameter, if set, should be set to `MBDirectionsProfileIdentifierAutomobile`, `MBDirectionsProfileIdentifierAutomobileAvoidingTraffic`, `MBDirectionsProfileIdentifierCycling`, or `MBDirectionsProfileIdentifierWalking`. `MBDirectionsProfileIdentifierAutomobile` is used by default.
     */
    public convenience init(locations: [CLLocation], profileIdentifier: MBDirectionsProfileIdentifier? = .automobileAvoidingTraffic) {
        self.init(waypoints: locations.map { Waypoint(location: $0) }, profileIdentifier: profileIdentifier)
    }
    
    
    /**
     Initializes a route options object for routes between the given geographic coordinates and an optional profile identifier optimized for navigation.
     
     - parameter coordinates: An array of geographic coordinates representing locations that the route should visit in chronological order. The array should contain at least two locations (the source and destination) and at most 25 locations. Each coordinate is converted into a `Waypoint` object.
     - parameter profileIdentifier: A string specifying the primary mode of transportation for the routes. This parameter, if set, should be set to `MBDirectionsProfileIdentifierAutomobile`, `MBDirectionsProfileIdentifierAutomobileAvoidingTraffic`, `MBDirectionsProfileIdentifierCycling`, or `MBDirectionsProfileIdentifierWalking`. `MBDirectionsProfileIdentifierAutomobile` is used by default.
     */
    public convenience init(coordinates: [CLLocationCoordinate2D], profileIdentifier: MBDirectionsProfileIdentifier? = .automobileAvoidingTraffic) {
        self.init(waypoints: coordinates.map { Waypoint(coordinate: $0) }, profileIdentifier: profileIdentifier)
    }
    
    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
}
