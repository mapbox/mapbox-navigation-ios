import CoreLocation
import MapboxDirections

/// ``NavigationProgress`` stores the user’s progress along a route.
public struct NavigationProgress: RouteProgressRepresentable, Equatable, Sendable {
    /// Returns the current main `Route`.
    public let route: Route
    /// Returns the id of the current main `Route`.
    public let routeId: RouteId

    /// Returns the progress along the current ``RouteLeg``.
    public let currentLegProgress: RouteLegProgress
    /// Total distance traveled by user along all legs.
    public let distanceTraveled: CLLocationDistance
    /// Number between 0 and 1 representing how far along the `Route` the user has traveled.
    public let fractionTraveled: Double
    /// Total seconds remaining on all legs.
    public let durationRemaining: TimeInterval
    /// Total distance remaining in meters along route.
    public let distanceRemaining: CLLocationDistance
    /// Index representing current ``RouteLeg``.
    public let legIndex: Int
    /// Index relative to route shape, representing the point the user is currently located at.
    public let shapeIndex: Int
    /// The waypoints of the route.
    public let waypoints: [Waypoint]

    /// Initializes a new ``NavigationProgress``.
    /// - Parameters:
    ///   - route: The current main `Route`.
    ///   - routeId: The id of the current main `Route`.
    ///   - currentLegProgress: The progress along the current ``RouteLeg``.
    ///   - distanceTraveled: Total distance traveled by user along all legs.
    ///   - fractionTraveled: Number between 0 and 1 representing how far along the `Route` the user has traveled.
    ///   - durationRemaining: Total seconds remaining on all legs.
    ///   - distanceRemaining: Total distance remaining in meters along route.
    ///   - legIndex: Index representing current ``RouteLeg``.
    ///   - shapeIndex: Index relative to route shape, representing the point the user is currently located at.
    ///   - waypoints: The waypoints of the route.
    public init(
        route: Route,
        routeId: RouteId,
        currentLegProgress: RouteLegProgress,
        distanceTraveled: CLLocationDistance,
        fractionTraveled: Double,
        durationRemaining: TimeInterval,
        distanceRemaining: CLLocationDistance,
        legIndex: Int,
        shapeIndex: Int,
        waypoints: [Waypoint]
    ) {
        self.route = route
        self.routeId = routeId
        self.currentLegProgress = currentLegProgress
        self.distanceTraveled = distanceTraveled
        self.fractionTraveled = fractionTraveled
        self.durationRemaining = durationRemaining
        self.distanceRemaining = distanceRemaining
        self.legIndex = legIndex
        self.shapeIndex = shapeIndex
        self.waypoints = waypoints
    }
}

extension NavigationProgress {
    init(_ routeProgress: RouteProgress) {
        self.route = routeProgress.route
        self.routeId = routeProgress.navigationRoutes.mainRoute.routeId
        self.currentLegProgress = routeProgress.currentLegProgress
        self.distanceTraveled = routeProgress.distanceTraveled
        self.fractionTraveled = routeProgress.fractionTraveled
        self.distanceRemaining = routeProgress.distanceRemaining
        self.durationRemaining = routeProgress.durationRemaining
        self.legIndex = routeProgress.legIndex
        self.shapeIndex = routeProgress.shapeIndex
        self.waypoints = routeProgress.waypoints
    }
}
