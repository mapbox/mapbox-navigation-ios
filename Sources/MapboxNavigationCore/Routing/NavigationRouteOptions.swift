import _MapboxNavigationHelpers
import CoreLocation
import Foundation
import MapboxDirections

/// A ``NavigationRouteOptions`` object specifies turn-by-turn-optimized criteria for results returned by the Mapbox
/// Directions API.
///
/// ``NavigationRouteOptions`` is a subclass of `RouteOptions` that has been optimized for navigation. Pass an instance
/// of this class into the ``RoutingProvider/calculateRoutes(options:)-3d0sf`` method.
///
/// This class implements the `NSCopying` protocol by round-tripping the object through `JSONEncoder` and `JSONDecoder`.
/// If you subclass ``NavigationRouteOptions``, make sure any properties you add are accounted for in `Decodable(from:)`
/// and `Encodable.encode(to:)`. If your subclass contains any customizations that cannot be represented in JSON, make
/// sure the subclass overrides `NSCopying.copy(with:)` to persist those customizations.
///
/// ``NavigationRouteOptions`` is designed to be used with the ``MapboxRoutingProvider`` class for specifying routing
/// criteria.
open class NavigationRouteOptions: RouteOptions, OptimizedForNavigation, @unchecked Sendable {
    /// Specifies the preferred distance measurement unit.
    ///
    /// Meters and feet will be used when the presented distances are small enough.
    /// See `DistanceFormatter` for more information.
    public var distanceUnit: LengthFormatter.Unit = Locale.current.usesMetricSystem ? .kilometer : .mile

    public convenience init(
        waypoints: [Waypoint],
        profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic,
        queryItems: [URLQueryItem]? = nil,
        locale: Locale,
        distanceUnit: LengthFormatter.Unit
    ) {
        self.init(
            waypoints: waypoints,
            profileIdentifier: profileIdentifier,
            queryItems: queryItems
        )
        self.locale = locale
        self.distanceUnit = distanceUnit
        distanceMeasurementSystem = .init(distanceUnit)
    }

    /// Initializes a navigation route options object for routes between the given waypoints and an optional profile
    /// identifier optimized for navigation.
    public required init(
        waypoints: [Waypoint],
        profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic,
        queryItems: [URLQueryItem]? = nil
    ) {
        super.init(
            waypoints: waypoints.map { waypoint in
                with(waypoint) {
                    $0.coordinateAccuracy = -1
                }
            },
            profileIdentifier: profileIdentifier,
            queryItems: queryItems
        )
        includesAlternativeRoutes = true
        attributeOptions = [.expectedTravelTime, .maximumSpeedLimit]
        let profile = profileIdentifier ?? .automobileAvoidingTraffic
        if profile.isAutomobileAvoidingTraffic {
            attributeOptions.update(with: .numericCongestionLevel)
            refreshingEnabled = true
        }
        includesExitRoundaboutManeuver = true

        optimizeForNavigation(queryItems: queryItems)
    }

    /// Initializes an equivalent `RouteOptions` object from a ``NavigationMatchOptions``.
    ///
    /// - SeeAlso: ``NavigationMatchOptions``.
    public convenience init(navigationMatchOptions options: NavigationMatchOptions) {
        self.init(waypoints: options.waypoints, profileIdentifier: options.profileIdentifier)
    }

    /// Initializes a navigation route options object for routes between the given locations and an optional profile
    /// identifier optimized for navigation.
    public convenience init(
        locations: [CLLocation],
        profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic,
        queryItems: [URLQueryItem]? = nil
    ) {
        self.init(
            waypoints: locations.map { Waypoint(location: $0) },
            profileIdentifier: profileIdentifier,
            queryItems: queryItems
        )
    }

    /// Initializes a route options object for routes between the given geographic coordinates and an optional profile
    /// identifier optimized for navigation.
    public convenience init(
        coordinates: [CLLocationCoordinate2D],
        profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic,
        queryItems: [URLQueryItem]? = nil
    ) {
        self.init(
            waypoints: coordinates.map { Waypoint(coordinate: $0) },
            profileIdentifier: profileIdentifier,
            queryItems: queryItems
        )
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

/// A ``NavigationMatchOptions`` object specifies turn-by-turn-optimized criteria for results returned by the Mapbox Map
/// Matching API.
///
/// ``NavigationMatchOptions`` is a subclass of `MatchOptions` that has been optimized for navigation. Pass an instance
/// of this class into the ``RoutingProvider/calculateRoutes(options:)`` method.
///
/// - Note: it is very important you specify the `waypoints` for the route. Usually the only two values for this
/// `IndexSet` will be 0 and the length of the coordinates. Otherwise, all coordinates passed through will be considered
/// waypoints.
open class NavigationMatchOptions: MatchOptions, OptimizedForNavigation, @unchecked Sendable {
    /// Specifies the preferred distance measurement unit.
    ///
    /// Meters and feet will be used when the presented distances are small enough. See `DistanceFormatter` for more
    /// information.
    public var distanceUnit: LengthFormatter.Unit = Locale.current.usesMetricSystem ? .kilometer : .mile

    public convenience init(
        waypoints: [Waypoint],
        profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic,
        queryItems: [URLQueryItem]? = nil,
        distanceUnit: LengthFormatter.Unit
    ) {
        self.init(
            waypoints: waypoints,
            profileIdentifier: profileIdentifier,
            queryItems: queryItems
        )
        self.distanceUnit = distanceUnit
        distanceMeasurementSystem = .init(distanceUnit)
    }

    /// Initializes a navigation route options object for routes between the given waypoints and an optional profile
    /// identifier optimized for navigation.
    ///
    /// - Seealso: `RouteOptions`.
    public required init(
        waypoints: [Waypoint],
        profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic,
        queryItems: [URLQueryItem]? = nil
    ) {
        super.init(
            waypoints: waypoints.map { waypoint in
                with(waypoint) {
                    $0.coordinateAccuracy = -1
                }
            },
            profileIdentifier: profileIdentifier,
            queryItems: queryItems
        )
        attributeOptions = [.expectedTravelTime]
        let profile = profileIdentifier ?? .automobileAvoidingTraffic
        if profile.isAutomobileAvoidingTraffic {
            attributeOptions.update(with: .numericCongestionLevel)
        }
        if profile.isAutomobile || profile.isAutomobileAvoidingTraffic {
            attributeOptions.insert(.maximumSpeedLimit)
        }

        optimizeForNavigation(queryItems: queryItems)
    }

    /// Initializes a navigation match options object for routes between the given locations and an optional profile
    /// identifier optimized for navigation.
    public convenience init(
        locations: [CLLocation],
        profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic,
        queryItems: [URLQueryItem]? = nil
    ) {
        self.init(
            waypoints: locations.map { Waypoint(location: $0) },
            profileIdentifier: profileIdentifier,
            queryItems: queryItems
        )
    }

    /// Initializes a navigation match options object for routes between the given geographic coordinates and an
    /// optional profile identifier optimized for navigation.
    public convenience init(
        coordinates: [CLLocationCoordinate2D],
        profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic,
        queryItems: [URLQueryItem]? = nil
    ) {
        self.init(
            waypoints: coordinates.map { Waypoint(coordinate: $0) },
            profileIdentifier: profileIdentifier,
            queryItems: queryItems
        )
    }

    public required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

private enum OptimizedForNavigationKey: String {
    case includesSteps = "steps"
    case shapeFormat = "geometries"
    case routeShapeResolution = "overview"
    case locale = "language"
    case includesSpokenInstructions = "voice_instructions"
    case distanceMeasurementSystem = "voice_units"
    case includesVisualInstructions = "banner_instructions"
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
    var distanceUnit: LengthFormatter.Unit { get }

    func optimizeForNavigation(queryItems: [URLQueryItem]?)
}

extension OptimizedForNavigation {
    func optimizeForNavigation(queryItems: [URLQueryItem]?) {
        let names = Set(queryItems?.map { $0.name } ?? [])

        if !names.contains(OptimizedForNavigationKey.shapeFormat.rawValue) {
            shapeFormat = .polyline6
        }
        if !names.contains(OptimizedForNavigationKey.includesSteps.rawValue) {
            includesSteps = true
        }
        if !names.contains(OptimizedForNavigationKey.routeShapeResolution.rawValue) {
            routeShapeResolution = .full
        }
        if !names.contains(OptimizedForNavigationKey.includesSpokenInstructions.rawValue) {
            includesSpokenInstructions = true
        }
        if !names.contains(OptimizedForNavigationKey.locale.rawValue) {
            locale = .nationalizedCurrent
        }
        if !names.contains(OptimizedForNavigationKey.distanceMeasurementSystem.rawValue) {
            distanceMeasurementSystem = .init(distanceUnit)
        }
        if !names.contains(OptimizedForNavigationKey.includesVisualInstructions.rawValue) {
            includesVisualInstructions = true
        }
    }
}
