import Combine
import Foundation

/// Provides control over main navigation states and transitions between them.
@MainActor
public protocol SessionController: Sendable {
    /// Transitions (or resumes) to the Free Drive mode.
    func startFreeDrive()
    /// Pauses the Free Drive.
    ///
    /// Does nothing if not in the Free Drive mode.
    func pauseFreeDrive()
    /// Transitions to Idle state.
    ///
    /// No navigation actions are performed in this state. Location updates are no collected and not processed.
    func setToIdle()
    /// Starts ActiveNavigation with the given `navigationRoutes`.
    /// - parameter navigationRoutes: A route to navigate.
    /// - parameter startLegIndex: A leg index, to start with. Usually start from `0`.
    func startActiveGuidance(with navigationRoutes: NavigationRoutes, startLegIndex: Int)

    /// Posts updates of the current session state.
    var session: AnyPublisher<Session, Never> { get }
    /// The current session state.
    @MainActor
    var currentSession: Session { get }

    /// Posts updates about the ``NavigationRoutes`` which navigator follows.
    var navigationRoutes: AnyPublisher<NavigationRoutes?, Never> { get }
    /// Current `NavigationRoutes` the navigator is following
    var currentNavigationRoutes: NavigationRoutes? { get }

    /// Explicitly attempts to stop location updates on the background.
    ///
    /// Call this method when app is going background mode and you want to stop user tracking.
    /// Works only for Free Drive mode, when ``CoreConfig/disableBackgroundTrackingLocation`` configuration is enabled.
    func disableTrackingBackgroundLocationIfNeeded()

    /// Resumes location tracking after restoring from background mode.
    ///
    /// Call this method on restoring to foreground if you want to continue user tracking.
    /// Works only for Free Drive mode, when ``CoreConfig/disableBackgroundTrackingLocation` configuration is enabled.
    func restoreTrackingLocationIfNeeded()
}
