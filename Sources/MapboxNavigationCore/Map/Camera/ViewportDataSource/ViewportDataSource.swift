import Combine
import CoreLocation
import MapboxMaps
import UIKit

/// Represents the state of the viewport.
public struct ViewportState: Equatable, Sendable {
    /// The current location of the user.
    public let location: CLLocation
    /// The navigation route progress.
    public let routeProgress: RouteProgress?
    /// The padding applied to the viewport.
    public let viewportPadding: UIEdgeInsets
    /// The current user heading.
    public let heading: CLHeading?

    /// Initializes a new ``ViewportState`` instance.
    /// - Parameters:
    ///   - location: The current location of the user.
    ///   - routeProgress: The navigation route progress. Pass `nil` in case of no active navigation at the moment.
    ///   - viewportPadding: The padding applied to the viewport.
    ///   - heading: The current user heading.
    public init(
        location: CLLocation,
        routeProgress: RouteProgress?,
        viewportPadding: UIEdgeInsets,
        heading: CLHeading?
    ) {
        self.location = location
        self.routeProgress = routeProgress
        self.viewportPadding = viewportPadding
        self.heading = heading
    }
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

extension CLHeading: @unchecked Sendable {}
