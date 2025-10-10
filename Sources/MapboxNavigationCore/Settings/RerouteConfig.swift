import Foundation
import MapboxDirections

/// Configures the rerouting behavior.
public struct RerouteConfig: Equatable {
    public typealias OptionsCustomization = EquatableClosure<RouteOptions, RouteOptions>

    /// Optional customization callback triggered on reroute attempts.
    ///
    /// Provide this callback if you need to modify route request options, done during building a reroute. This will
    /// not affect initial route requests.
    @available(*, deprecated, message: """
    Use urlOptionsCustomization instead. Using optionsCustomization may lead to losing custom query items at reroutes.
    """)
    public var optionsCustomization: OptionsCustomization? {
        set { deprecatedOptionsCustomization = newValue }
        get { deprecatedOptionsCustomization }
    }

    var deprecatedOptionsCustomization: OptionsCustomization?

    /// Enables or disables rerouting mechanism.
    ///
    /// Disabling rerouting will result in the route remaining unchanged even if the user wanders off of it.
    /// Reroute detecting is enabled by default.
    public var detectsReroute: Bool

    /// Reroute strategy for Map Matching API routes.
    ///
    /// Defaults to ``RerouteStrategyForMatchRoute/rerouteDisabled``.
    public var rerouteStrategyForMatchRoute: RerouteStrategyForMatchRoute

    public typealias UrlOptionsCustomization = EquatableClosure<String, String>

    /// Optional customization callback triggered on reroute attempts.
    ///
    /// Provide this callback if you need to add additional query parameters to the reroute request URL.
    /// This will not affect initial route requests.
    public var urlOptionsCustomization: UrlOptionsCustomization?

    @available(*, deprecated, message: """
    Use init(detectsReroute:rerouteStrategyForMatchRoute:urlOptionsCustomization:) instead. 
    Using optionsCustomization may lead to losing custom query items at reroutes.
    """)
    public init(
        detectsReroute: Bool = true,
        rerouteStrategyForMatchRoute: RerouteStrategyForMatchRoute = .rerouteDisabled,
        optionsCustomization: OptionsCustomization? = nil
    ) {
        self.detectsReroute = detectsReroute
        self.rerouteStrategyForMatchRoute = rerouteStrategyForMatchRoute
        self.optionsCustomization = optionsCustomization
    }

    public init(
        detectsReroute: Bool = true,
        rerouteStrategyForMatchRoute: RerouteStrategyForMatchRoute = .rerouteDisabled,
        urlOptionsCustomization: UrlOptionsCustomization? = nil
    ) {
        self.detectsReroute = detectsReroute
        self.rerouteStrategyForMatchRoute = rerouteStrategyForMatchRoute
        self.urlOptionsCustomization = urlOptionsCustomization
    }

    public init(
        detectsReroute: Bool = true,
        rerouteStrategyForMatchRoute: RerouteStrategyForMatchRoute = .rerouteDisabled
    ) {
        self.init(
            detectsReroute: detectsReroute,
            rerouteStrategyForMatchRoute: rerouteStrategyForMatchRoute,
            urlOptionsCustomization: nil
        )
    }
}
