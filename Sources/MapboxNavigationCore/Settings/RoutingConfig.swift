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
    /// This property is ignored unless ``profileIdentifier`` is `ProfileIdentifier.automobileAvoidingTraffic`.
    /// Use `nil` value to disable the mechanism.
    public var routeRefreshPeriod: TimeInterval?

    /// Type of routing to be used by various SDK objects when providing route calculations. Use this value to configure
    /// online vs. offline data usage for routing.
    ///
    /// Default value is ``RoutingProviderSource/hybrid``
    public var routingProviderSource: RoutingProviderSource

    /// Enables automatic switching to online version of the current route when possible.
    ///
    /// Indicates if ``NavigationController`` will attempt to detect if thr current route was build offline and if there
    /// is an online route with the same path is available to automatically switch to it. Using online route is
    /// beneficial due to available live data like traffic congestion, incidents, etc. Check is not performed instantly
    /// and it is not guaranteed to receive an online version at any given period of time.
    ///
    /// Enabled by default.
    public var prefersOnlineRoute: Bool

    @available(
        *,
        deprecated,
        message: "Use 'init(alternativeRoutesDetectionConfig:fasterRouteDetectionConfig:rerouteConfig:initialManeuverAvoidanceRadius:routeRefreshPeriod:routingProviderSource:prefersOnlineRoute:)' instead."
    )
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

    public init(
        alternativeRoutesDetectionConfig: AlternativeRoutesDetectionConfig? = .init(),
        fasterRouteDetectionConfig: FasterRouteDetectionConfig? = .init(),
        rerouteConfig: RerouteConfig = .init(),
        initialManeuverAvoidanceRadius: TimeInterval = 8,
        routeRefreshPeriod: TimeInterval? = 120,
        routingProviderSource: RoutingProviderSource = .hybrid,
        prefersOnlineRoute: Bool = true
    ) {
        self.alternativeRoutesDetectionConfig = alternativeRoutesDetectionConfig
        self.fasterRouteDetectionConfig = fasterRouteDetectionConfig
        self.rerouteConfig = rerouteConfig
        self.initialManeuverAvoidanceRadius = initialManeuverAvoidanceRadius
        self.routeRefreshPeriod = routeRefreshPeriod
        self.routingProviderSource = routingProviderSource
        self.prefersOnlineRoute = prefersOnlineRoute
    }
}
