import Foundation
import CoreLocation
import MapboxDirections

/**
 A `NavigationRouteOptions` object specifies turn-by-turn-optimized criteria for results returned by the Mapbox Directions API.

 `NavigationRouteOptions` is a subclass of `RouteOptions` that has been optimized for navigation. Pass an instance of this class into the `Directions.calculate(_:completionHandler:)` method.
 
 This class implements the `NSCopying` protocol by round-tripping the object through `JSONEncoder` and `JSONDecoder`. If you subclass `NavigationRouteOptions`, make sure any properties you add are accounted for in `Decodable(from:)` and `Encodable.encode(to:)`. If your subclass contains any customizations that cannot be represented in JSON, make sure the subclass overrides `NSCopying.copy(with:)` to persist those customizations.
 
 `NavigationRouteOptions` is designed to be used with the `Directions` and `NavigationDirections` classes for specifying routing criteria. To customize the user experience in a `NavigationViewController`, use the `NavigationOptions` class.
 */
open class NavigationRouteOptions: RouteOptions, OptimizedForNavigation {
    /**
     Initializes a navigation route options object for routes between the given waypoints and an optional profile identifier optimized for navigation.

     - seealso: `RouteOptions`
     */
    public required init(waypoints: [Waypoint], profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic) {
        super.init(waypoints: waypoints.map {
            $0.coordinateAccuracy = -1
            return $0
        }, profileIdentifier: profileIdentifier)
        includesAlternativeRoutes = true
        attributeOptions = [.expectedTravelTime, .maximumSpeedLimit]
        if profileIdentifier == .cycling {
            // https://github.com/mapbox/mapbox-navigation-ios/issues/3495
            attributeOptions.update(with: .congestionLevel)
        } else {
            attributeOptions.update(with: .numericCongestionLevel)
        }
        includesExitRoundaboutManeuver = true
        if profileIdentifier == .automobileAvoidingTraffic {
            refreshingEnabled = true
        }

        optimizeForNavigation()
    }

    /**
     Initializes an equivalent `RouteOptions` object from a `NavigationMapOptions`
     
     - seealso: `NavigationMatchOptions`
     */
    public convenience init(navigationMatchOptions options: NavigationMatchOptions) {
        self.init(waypoints: options.waypoints, profileIdentifier: options.profileIdentifier)
    }
    /**
     Initializes a navigation route options object for routes between the given locations and an optional profile identifier optimized for navigation.

     - seealso: `RouteOptions`
     */
    public convenience init(locations: [CLLocation], profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic) {
        self.init(waypoints: locations.map { Waypoint(location: $0) }, profileIdentifier: profileIdentifier)
    }

    /**
     Initializes a route options object for routes between the given geographic coordinates and an optional profile identifier optimized for navigation.

     - seealso: `RouteOptions`
     */
    public convenience init(coordinates: [CLLocationCoordinate2D], profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic) {
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
open class NavigationMatchOptions: MatchOptions, OptimizedForNavigation {
    /**
     Initializes a navigation route options object for routes between the given waypoints and an optional profile identifier optimized for navigation.
     
     - seealso: `RouteOptions`
     */
    public required init(waypoints: [Waypoint], profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic) {
        super.init(waypoints: waypoints.map {
            $0.coordinateAccuracy = -1
            return $0
        }, profileIdentifier: profileIdentifier)
        attributeOptions = [.numericCongestionLevel, .expectedTravelTime]
        if profileIdentifier == .automobile || profileIdentifier == .automobileAvoidingTraffic {
            attributeOptions.insert(.maximumSpeedLimit)
        }

        optimizeForNavigation()
    }
    
    
    /**
     Initializes a navigation match options object for routes between the given locations and an optional profile identifier optimized for navigation.
     
     - seealso: `MatchOptions`
     */
    public convenience init(locations: [CLLocation], profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic) {
        self.init(waypoints: locations.map { Waypoint(location: $0) }, profileIdentifier: profileIdentifier)
    }
    
    /**
     Initializes a navigation match options object for routes between the given geographic coordinates and an optional profile identifier optimized for navigation.
     
     - seealso: `MatchOptions`
     */
    public convenience init(coordinates: [CLLocationCoordinate2D], profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic) {
        self.init(waypoints: coordinates.map { Waypoint(coordinate: $0) }, profileIdentifier: profileIdentifier)
    }
    
    required public init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

protocol OptimizedForNavigation: AnyObject {
    var includesSteps: Bool { get set }
    var routeShapeResolution: RouteShapeResolution { get set }
    var shapeFormat: RouteShapeFormat { get set }
    var attributeOptions: AttributeOptions { get set }
    var locale: Locale { get set }
    var distanceMeasurementSystem: MeasurementSystem { get set }
    var includesSpokenInstructions: Bool { get set }
    var includesVisualInstructions: Bool { get set }
    
    func optimizeForNavigation()
}

extension OptimizedForNavigation {
    func optimizeForNavigation() {
        shapeFormat = .polyline6
        includesSteps = true
        routeShapeResolution = .full
        includesSpokenInstructions = true
        locale = Locale.nationalizedCurrent
        distanceMeasurementSystem = .init(NavigationSettings.shared.distanceUnit)
        includesVisualInstructions = true
    }
}
