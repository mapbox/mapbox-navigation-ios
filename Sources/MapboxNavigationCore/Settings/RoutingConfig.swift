import Foundation

/// Routing Configuration.
public struct RoutingConfig: Equatable {
    /// Options to configure fetching, detecting, and accepting ``AlternativeRoute``s during navigation.
    ///
    /// Use `nil` value to disable the mechanism
    public var alternativeRoutesDetectionConfig: AlternativeRoutesDetectionConfig?

    /// Options to configure fetching, detecting, and accepting a faster route during active guidance.
    ///
    /// Use `nil` value to disable the mechanism.
    public var fasterRouteDetectionConfig: FasterRouteDetectionConfig?

    /// Configures the rerouting behavior.
    public var rerouteConfig: RerouteConfig

    /// A radius around the current user position in which the API will avoid returning any significant maneuvers when
    /// rerouting or suggesting alternative routes.
    /// Provided `TimeInterval` value will be converted to meters using current speed. Default value is `8` seconds.
    public var initialManeuverAvoidanceRadius: TimeInterval

    /// A time interval in which time-dependent properties of the ``RouteLeg``s of the resulting `Route`s will be
    /// refreshed.
    ///
    /// This property is ignored unless `profileIdentifier` is `ProfileIdentifier.automobileAvoidingTraffic`. Use `nil`
    /// value to disable the mechanism
    public var routeRefreshPeriod: TimeInterval?
    public var routingProviderSource: RoutingProviderSource
    public var prefersOnlineRoute: Bool

    public init(
        alternativeRoutesDetectionSettings: AlternativeRoutesDetectionConfig? = .init(),
        fasterRouteDetectionSettings: FasterRouteDetectionConfig? = .init(),
        rerouteSettings: RerouteConfig = .init(),
        initialManeuverAvoidanceRadius: TimeInterval = 8,
        routeRefreshPeriod: TimeInterval? = 120,
        routingProviderSource: RoutingProviderSource = .hybrid,
        prefersOnlineRoute: Bool = true,
        detectsReroute: Bool = true
    ) {
        self.alternativeRoutesDetectionConfig = alternativeRoutesDetectionSettings
        self.fasterRouteDetectionConfig = fasterRouteDetectionSettings
        self.rerouteConfig = rerouteSettings
        self.initialManeuverAvoidanceRadius = initialManeuverAvoidanceRadius
        self.routeRefreshPeriod = routeRefreshPeriod
        self.routingProviderSource = routingProviderSource
        self.prefersOnlineRoute = prefersOnlineRoute
    }
}
