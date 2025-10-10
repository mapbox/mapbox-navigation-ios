import Combine
import CoreLocation
import MapboxMaps
import UIKit

/// Represents the state of the viewport.
public struct ViewportState: Equatable, Sendable {
    /// The current location of the user.
    public let navigationLocation: NavigationLocation
    /// The navigation route progress.
    public let navigationProgress: NavigationProgress?
    /// The padding applied to the viewport.
    public let viewportPadding: UIEdgeInsets
    /// The current user heading.
    public let navigationHeading: NavigationHeading?

    /// Initializes a new ``ViewportState`` instance.
    /// - Parameters:
    ///   - navigationLocation: The current location of the user.
    ///   - navigationProgress: The navigation route progress. Pass `nil` in case of no active navigation at the moment.
    ///   - viewportPadding: The padding applied to the viewport.
    ///   - navigationHeading: The current user heading.
    public init(
        navigationLocation: NavigationLocation,
        navigationProgress: NavigationProgress?,
        viewportPadding: UIEdgeInsets,
        navigationHeading: NavigationHeading?
    ) {
        self.navigationLocation = navigationLocation
        self.navigationProgress = navigationProgress
        self.viewportPadding = viewportPadding
        self.navigationHeading = navigationHeading
    }

    /// Initializes a new ``ViewportState`` instance.
    /// - Parameters:
    ///   - location: The current location of the user.
    ///   - routeProgress: The navigation route progress. Pass `nil` in case of no active navigation at the moment.
    ///   - viewportPadding: The padding applied to the viewport.
    ///   - heading: The current user heading.
    @available(
        *,
        deprecated,
        message: "Use `init(navigationLocation:navigationProgress:viewportPadding:navigationHeading:)` instead"
    )
    public init(
        location: CLLocation,
        routeProgress: RouteProgress?,
        viewportPadding: UIEdgeInsets,
        heading: CLHeading?
    ) {
        self.navigationLocation = NavigationLocation(location)
        self.navigationProgress = routeProgress.map(NavigationProgress.init)
        self.viewportPadding = viewportPadding
        self.navigationHeading = heading.map(NavigationHeading.init)
    }
}

extension ViewportState {
    /// The current user heading. Use ``navigationHeading`` instead. Always returns `nil`.
    @available(*, deprecated, message: "Use `navigationHeading` instead")
    public var heading: CLHeading? { return nil }

    /// The current location of the user. Use ``navigationLocation`` instead.
    @available(*, deprecated, message: "Use `navigationLocation` instead")
    public var location: CLLocation {
        navigationLocation.clLocation
    }

    /// The navigation route progress. Use ``navigationProgress`` instead. Always returns `nil`.
    @available(*, deprecated, message: "Use `navigationProgress` instead")
    public var routeProgress: RouteProgress? { return nil }
}

/// The protocol, which is used to fill and store ``NavigationCameraOptions`` which will be used by ``NavigationCamera``
/// for execution of transitions and continuous updates.
///
/// By default Navigation SDK for iOS provides default implementation of ``ViewportDataSource`` in
/// ``MobileViewportDataSource`` and ``CarPlayViewportDataSource``.
@MainActor
public protocol ViewportDataSource: AnyObject {
    /// Options, which give the ability to control whether certain `CameraOptions` will be generated.
    var options: NavigationViewportDataSourceOptions { get }

    /// Notifies that the navigation camera options have changed in response to a viewport change.
    var navigationCameraOptions: AnyPublisher<NavigationCameraOptions, Never> { get }

    /// The last calculated ``NavigationCameraOptions``.
    var currentNavigationCameraOptions: NavigationCameraOptions { get }

    /// Updates ``NavigationCameraOptions`` accoridng to the navigation state.
    /// - Parameters:
    ///   - viewportState: The current viewport state.
    func update(using viewportState: ViewportState)
}
