import Combine
import CoreLocation
import Foundation
import MapboxDirections

/// Provides control over various aspects of the navigation process, mainly Active Guidance.
@MainActor
public protocol NavigationController: Sendable {
    /// Programmatically switches between available continuous alternatvies
    /// - parameter index: An index of an alternative in ``NavigationRoutes/alternativeRoutes``
    func selectAlternativeRoute(at index: Int)
    /// Programmatically switches between available continuous alternatvies
    /// - parameter routeId: ``AlternativeRoute/id-swift.property`` of an alternative
    func selectAlternativeRoute(with routeId: RouteId)
    /// Manually switches current route leg.
    /// - parameter newLegIndex: A leg index to switch to.
    func switchLeg(newLegIndex: Int)
    /// Posts heading updates.
    var heading: AnyPublisher<CLHeading, Never> { get }

    /// Posts map matching updates, including location, current speed and speed limits, road info and map matching
    /// details.
    ///
    /// - Note: To receive map matching updates through subscribres, initiate a free drive session by
    ///   invoking ``SessionController/startFreeDrive()`` or start an active guidance session
    ///   by invoking ``SessionController/startActiveGuidance(with:startLegIndex:)``.
    var locationMatching: AnyPublisher<MapMatchingState, Never> { get }
    /// Includes current location, speed, road info and additional map matching details.
    var currentLocationMatching: MapMatchingState? { get }
    /// Posts current route progress updates.
    ///
    /// - Note: This functionality is limited to the active guidance mode.
    var routeProgress: AnyPublisher<RouteProgressState?, Never> { get }
    /// Current route progress updates.
    ///
    /// - Note: This functionality is limited to the active guidance mode.
    var currentRouteProgress: RouteProgressState? { get }

    /// Posts updates about Navigator going to switch it's tiles version.
    var offlineFallbacks: AnyPublisher<FallbackToTilesState, Never> { get }

    /// Posts updates about upcoming voice instructions.
    var voiceInstructions: AnyPublisher<SpokenInstructionState, Never> { get }
    /// Posts updates about upcoming visual instructions.
    var bannerInstructions: AnyPublisher<VisualInstructionState, Never> { get }

    /// Posts updates about arriving to route waypoints.
    var waypointsArrival: AnyPublisher<WaypointArrivalStatus, Never> { get }
    /// Posts updates about rerouting events and progress.
    var rerouting: AnyPublisher<ReroutingStatus, Never> { get }
    /// Posts updates about continuous alternatives changes during the trip.
    var continuousAlternatives: AnyPublisher<AlternativesStatus, Never> { get }
    /// Posts updates about faster routes applied during the trip.
    var fasterRoutes: AnyPublisher<FasterRoutesStatus, Never> { get }
    /// Posts updates about route refreshing process.
    var routeRefreshing: AnyPublisher<RefreshingStatus, Never> { get }

    /// Posts updates about navigation-related errors happen.
    var errors: AnyPublisher<NavigatorError, Never> { get }
}
