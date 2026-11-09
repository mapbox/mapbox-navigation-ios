import Combine
import MapboxDirections
import MapboxMaps
import UIKit

/// A protocol that provides a way to customize route callout views on a navigation map.
///
/// By implementing this protocol, developers can customize the appearance and behavior
/// of route callouts to match their application's design and requirements.
///
/// - Note: This protocol must be implemented on the main actor as it deals with UI components.
@_spi(ExperimentalMapboxAPI)
@MainActor
public protocol RouteCalloutViewProvider {
    /// The configurations for how the route callout views should be anchored to the map.
    var anchorConfigs: [ViewAnnotationAnchorConfig] { get }

    /// Creates a dictionary of route callout view containers for a set of navigation routes.
    ///
    /// This method is called when the navigation map needs to display route callouts for primary and alternative
    /// routes.
    /// The implementation should create appropriate views for each route and return them in a dictionary mapped by
    /// route ID.
    ///
    /// - Parameter navigationRoutes: The primary and alternative routes for which to create callout views.
    /// - Returns: A dictionary mapping route IDs to their corresponding callout view containers.
    func createRouteCalloutViewContainers(
        for navigationRoutes: NavigationRoutes
    ) -> [RouteId: RouteCalloutViewContainer]

    /// A publisher that emits an event when route callouts need to be redrawn.
    ///
    /// This publisher should emit an event after some observed state change or the provider's settings change
    /// that affect how route callouts should be rendered (change of style, etc.).
    var redrawRequestPublisher: AnyPublisher<Void, Never> { get }
}

/// A container for a route callout view that defines how the view should be presented on the map.
///
/// This struct encapsulates a `UIView` that will be displayed as a route callout,
/// together with configuration for where along the route it can be placed and how it should respond
/// to changes in anchor configuration.
@_spi(ExperimentalMapboxAPI)
public struct RouteCalloutViewContainer {
    /// The default range of allowable positions along a route where a callout can be placed.
    ///
    /// The range is from 0.0 (start of route) to 1.0 (end of route).
    /// Default range is 0.2...0.8, which means callouts will be placed between 20% and 80% along the route.
    public static let defaultAllowedRouteOffsetRange: ClosedRange<Double> = 0.2...0.8

    /// Where a callout is placed within ``RouteCalloutViewContainer/allowedRouteOffsetRange``.
    public enum Placement: Equatable, Sendable {
        /// The map picks the position anywhere within the range.
        case automatic
        /// A fixed fraction of the range, from 0.0 (its start) to 1.0 (its end).
        case fixed(Double)
    }

    /// The view that will be displayed as a route callout.
    public let view: UIView

    /// The range along the route (from 0.0 to 1.0) where this callout is allowed to be positioned.
    ///
    /// Values are clamped between 0.0 (start of route) and 1.0 (end of route).
    public let allowedRouteOffsetRange: ClosedRange<Double>

    /// Where the callout is placed within ``allowedRouteOffsetRange``.
    ///
    /// A ``Placement/fixed(_:)`` fraction is clamped between 0.0 and 1.0.
    public let placement: Placement

    /// A closure that's called when the anchor configuration for this callout changes.
    ///
    /// This closure can be used to update the callout's appearance based on its anchor position.
    public let onAnchorConfigChanged: (ViewAnnotationAnchorConfig) -> Void

    /// Creates a new route callout view container.
    ///
    /// - Parameters:
    ///   - view: The view to display as a route callout.
    ///   - allowedRouteOffsetRange: The range along the route where this callout can be positioned.
    ///     Defaults to `defaultAllowedRouteOffsetRange`.
    ///   - placement: Where the callout is placed within `allowedRouteOffsetRange`. Defaults to `.automatic`.
    ///   - onAnchorConfigChanged: A closure that's called when the anchor configuration changes.
    public init(
        view: UIView,
        allowedRouteOffsetRange: ClosedRange<Double> = defaultAllowedRouteOffsetRange,
        placement: Placement = .automatic,
        onAnchorConfigChanged: @escaping (ViewAnnotationAnchorConfig) -> Void
    ) {
        self.view = view
        self.allowedRouteOffsetRange = allowedRouteOffsetRange.clamped(to: 0.0...1.0)
        self.placement = switch placement {
        case .automatic: .automatic
        case .fixed(let fraction): .fixed(fraction.clamped(to: 0.0...1.0))
        }
        self.onAnchorConfigChanged = onAnchorConfigChanged
    }
}
