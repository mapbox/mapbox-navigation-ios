import Combine
import CoreLocation
import MapboxNavigationCore

/// Customization options for the navigation preview user experience in a ``PreviewViewController``.
public struct PreviewOptions {
    /// The styles that the ``PreviewViewController``'s internal ``StyleManager`` object can select from
    /// for display.
    ///
    /// If this property is set to `nil`, a `StandardDayStyle` and a `StandardNightStyle` are created to be used as the
    /// `PreviewViewController`'s styles. This property is set to `nil` by default.
    public private(set) var styles: [Style]?

    let locationMatching: AnyPublisher<MapMatchingState, Never>
    let routeProgress: AnyPublisher<RouteProgress?, Never>
    let heading: AnyPublisher<CLHeading, Never>?
    let predictiveCacheManager: PredictiveCacheManager?

    /// Initializes `PreviewOptions` that is used as a configuration for the `PreviewViewController`.
    ///
    /// - Parameters:
    ///   - styles: The user interface styles that are available for display.
    ///   - locationMatching: A publisher that emits map matching updates.
    ///   - routeProgress: A publisher that emits route navigation progress.
    ///   - heading: A publisher that emits current user heading. Defaults to `nil.`
    ///   - predictiveCacheManager: An instance of `PredictiveCacheManager` used to continuously cache upcoming map
    /// tiles.
    public init(
        styles: [Style]? = nil,
        locationMatching: AnyPublisher<MapMatchingState, Never>,
        routeProgress: AnyPublisher<RouteProgress?, Never>,
        heading: AnyPublisher<CLHeading, Never>? = nil,
        predictiveCacheManager: PredictiveCacheManager? = nil
    ) {
        self.styles = styles
        self.locationMatching = locationMatching
        self.routeProgress = routeProgress
        self.heading = heading
        self.predictiveCacheManager = predictiveCacheManager
    }
}
