import Foundation
import MapboxDirections

/// Configures the rerouting behavior.
public struct RerouteConfig: Equatable {
    public typealias OptionsCustomization = EquatableClosure<RouteOptions, RouteOptions>

    /// Optional customization callback triggered on reroute attempts.
    ///
    /// Provide this callback if you need to modify route request options, done during building a reroute. This will
    /// not affect initial route requests.
    public var optionsCustomization: OptionsCustomization?
    /// Enables or disables rerouting mechanism.
    ///
    /// Disabling rerouting will result in the route remaining unchanged even if the user wanders off of it.
    /// Reroute detecting is enabled by default.
    public var detectsReroute: Bool

    public init(
        detectsReroute: Bool = true,
        optionsCustomization: OptionsCustomization? = nil
    ) {
        self.detectsReroute = detectsReroute
        self.optionsCustomization = optionsCustomization
    }
}
