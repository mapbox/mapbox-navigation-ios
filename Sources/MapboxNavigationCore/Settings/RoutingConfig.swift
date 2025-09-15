import Foundation

/// Routing Configuration.
public struct RoutingConfig: Equatable {
    /// A tile dataset used to use when querying routing tiles. This value should match the `profileIdentifier` in
    /// `DirectionsOptions` used to request routes.
    ///
    /// This property can only be modified before creating ``MapboxRoutingProvider`` instance. All further changes will
    /// have no effect.
    /// `ProfileIdentifier.automobileAvoidingTraffic` is used by default.
    public let datasetProfileIdentifier: ProfileIdentifier?

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

    /// Indicates if the expiration time of the route should be ignored during route refresh. The refresh period is
    /// controlled by server responses and may differ from the default value.
    ///
    /// This property is ignored unless ``profileIdentifier`` is `ProfileIdentifier.automobileAvoidingTraffic` and
    /// ``routeRefreshPeriod`` is not `nil`.
    ///
    ///  The default value of this property is `false`.
    public var ignoreExpirationTimeInRefresh: Bool

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
        message: "Use 'init(datasetProfileIdentifier:alternativeRoutesDetectionConfig:fasterRouteDetectionConfig:rerouteConfig:initialManeuverAvoidanceRadius:routeRefreshPeriod:routingProviderSource:prefersOnlineRoute:)' instead."
    )
    public init(
        alternativeRoutesDetectionSettings: AlternativeRoutesDetectionConfig? = .init(),
        fasterRouteDetectionSettings: FasterRouteDetectionConfig? = .init(),
        rerouteSettings: RerouteConfig = .init(),
        initialManeuverAvoidanceRadius: TimeInterval = 8,
        routeRefreshPeriod: TimeInterval? = 120,
        routingProviderSource: RoutingProviderSource = .hybrid,
        prefersOnlineRoute: Bool = true,
        detectsReroute: Bool,
        ignoreExpirationTimeInRefresh: Bool = false
    ) {
        self.init(
            datasetProfileIdentifier: nil,
            alternativeRoutesDetectionConfig: alternativeRoutesDetectionSettings,
            fasterRouteDetectionConfig: fasterRouteDetectionSettings,
            rerouteConfig: rerouteSettings,
            initialManeuverAvoidanceRadius: initialManeuverAvoidanceRadius,
            routeRefreshPeriod: routeRefreshPeriod,
            routingProviderSource: routingProviderSource,
            prefersOnlineRoute: prefersOnlineRoute,
            ignoreExpirationTimeInRefresh: ignoreExpirationTimeInRefresh
        )
    }

    public init(
        datasetProfileIdentifier: ProfileIdentifier? = nil,
        alternativeRoutesDetectionConfig: AlternativeRoutesDetectionConfig? = .init(),
        fasterRouteDetectionConfig: FasterRouteDetectionConfig? = .init(),
        rerouteConfig: RerouteConfig = .init(),
        initialManeuverAvoidanceRadius: TimeInterval = 8,
        routeRefreshPeriod: TimeInterval? = 120,
        routingProviderSource: RoutingProviderSource = .hybrid,
        prefersOnlineRoute: Bool = true,
        ignoreExpirationTimeInRefresh: Bool = false
    ) {
        self.datasetProfileIdentifier = datasetProfileIdentifier
        self.alternativeRoutesDetectionConfig = alternativeRoutesDetectionConfig
        self.fasterRouteDetectionConfig = fasterRouteDetectionConfig
        self.rerouteConfig = rerouteConfig
        self.initialManeuverAvoidanceRadius = initialManeuverAvoidanceRadius
        self.routeRefreshPeriod = routeRefreshPeriod
        self.routingProviderSource = routingProviderSource
        self.prefersOnlineRoute = prefersOnlineRoute
        self.ignoreExpirationTimeInRefresh = ignoreExpirationTimeInRefresh
    }
}
