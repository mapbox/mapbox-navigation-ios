import Foundation
import MapboxDirections

/**
 A `NavigationRouteOptions` object specifies turn-by-turn-optimized criteria for results returned by the Mapbox Directions API.

 `NavigationRouteOptions` is a subclass of `RouteOptions` that has been optimized for navigation. Pass an instance of this class into the `Directions.calculate(_:completionHandler:)` method.
 */
@objc(MBNavigationRouteOptions)
open class NavigationRouteOptions: RouteOptions {

    /**
     Initializes a navigation route options object for routes between the given waypoints and an optional profile identifier optimized for navigation.

     - SeeAlso:
     [RouteOptions](https://www.mapbox.com/mapbox-navigation-ios/directions/0.10.1/Classes/RouteOptions.html)
     */
    @objc public override init(waypoints: [Waypoint], profileIdentifier: MBDirectionsProfileIdentifier? = .automobileAvoidingTraffic) {
        super.init(waypoints: waypoints.map {
            $0.coordinateAccuracy = -1
            return $0
        }, profileIdentifier: profileIdentifier)
        includesAlternativeRoutes = true
        includesSteps = true
        routeShapeResolution = .full
        attributeOptions = [.congestionLevel, .expectedTravelTime]
        includesSpokenInstructions = true
        locale = Locale.nationalizedCurrent
        distanceMeasurementSystem = Locale.current.usesMetricSystem ? .metric : .imperial
        includesVisualInstructions = true
        includesExitRoundaboutManeuver = true
    }

    /**
     Initializes a navigation route options object for routes between the given locations and an optional profile identifier optimized for navigation.

     - SeeAlso:
     [RouteOptions](https://www.mapbox.com/mapbox-navigation-ios/directions/0.10.1/Classes/RouteOptions.html)
     */
    @objc public convenience init(locations: [CLLocation], profileIdentifier: MBDirectionsProfileIdentifier? = .automobileAvoidingTraffic) {
        self.init(waypoints: locations.map { Waypoint(location: $0) }, profileIdentifier: profileIdentifier)
    }

    /**
     Initializes a route options object for routes between the given geographic coordinates and an optional profile identifier optimized for navigation.

     - SeeAlso:
     [RouteOptions](https://www.mapbox.com/mapbox-navigation-ios/directions/0.10.1/Classes/RouteOptions.html)
     */
    @objc public convenience init(coordinates: [CLLocationCoordinate2D], profileIdentifier: MBDirectionsProfileIdentifier? = .automobileAvoidingTraffic) {
        self.init(waypoints: coordinates.map { Waypoint(coordinate: $0) }, profileIdentifier: profileIdentifier)
    }

    @objc public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
}
