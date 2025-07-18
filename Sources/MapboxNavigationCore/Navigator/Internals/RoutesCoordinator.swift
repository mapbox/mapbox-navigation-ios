import Foundation
import MapboxNavigationNative_Private

/// Coordinating routes update to NavNative Navigator to rule out some edge scenarios.
final class RoutesCoordinator {
    private enum State {
        case passiveNavigation
        case activeNavigation(UUID)
    }

    typealias RoutesResult = (mainRouteInfo: RouteInfo?, alternativeRoutes: [RouteAlternative])
    typealias RoutesSetupHandler = @MainActor (
        _ routesData: RoutesData?,
        _ legIndex: UInt32,
        _ reason: SetRoutesReason,
        _ completion: @escaping (Result<RoutesResult, Error>) -> Void
    ) -> Void
    typealias AlternativeRoutesSetupHandler = @MainActor (
        _ routes: [RouteInterface],
        _ completion: @escaping (Result<[RouteAlternative], Error>) -> Void
    ) -> Void

    private let routesSetupHandler: RoutesSetupHandler
    private let alternativeRoutesSetupHandler: AlternativeRoutesSetupHandler
    /// The lock that protects mutable state in `RoutesCoordinator`.
    private let lock: NSLock
    private var state: State

    /// Create a new coordinator that will coordinate  requests to set main and alternative routes.
    /// - Parameter routesSetupHandler: The handler that passes main and alternative route's`RouteInterface` objects to
    /// underlying Navigator.
    /// - Parameter alternativeRoutesSetupHandler: The handler that passes only alternative route's`RouteInterface`
    /// objects to underlying Navigator. Main route must be set before and it will remain unchanged.
    init(
        routesSetupHandler: @escaping RoutesSetupHandler,
        alternativeRoutesSetupHandler: @escaping AlternativeRoutesSetupHandler
    ) {
        self.routesSetupHandler = routesSetupHandler
        self.alternativeRoutesSetupHandler = alternativeRoutesSetupHandler
        self.lock = .init()
        self.state = .passiveNavigation
    }

    /// - Parameters:
    ///   - uuid: The UUID of the current active guidances session. All reroutes should have the same uuid.
    ///   - legIndex: The index of the leg along which to begin navigating.
    @MainActor
    func beginActiveNavigation(
        with routesData: RoutesData,
        uuid: UUID,
        legIndex: UInt32,
        reason: SetRoutesReason,
        completion: @escaping (Result<RoutesResult, Error>) -> Void
    ) {
        lock.lock()
        state = .activeNavigation(uuid)
        lock.unlock()

        routesSetupHandler(routesData, legIndex, reason, completion)
    }

    /// - Parameters:
    ///   - uuid: The UUID that was passed to `RoutesCoordinator.beginActiveNavigation(with:uuid:completion:)` method.
    @MainActor
    func endActiveNavigation(with uuid: UUID, completion: @escaping (Result<RoutesResult, Error>) -> Void) {
        lock.lock()
        guard case .activeNavigation(let currentUUID) = state, currentUUID == uuid else {
            lock.unlock()
            completion(.failure(RoutesCoordinatorError.endingInvalidActiveNavigation))
            return
        }
        state = .passiveNavigation
        lock.unlock()
        routesSetupHandler(nil, 0, .cleanUp, completion)
    }

    @MainActor
    func updateAlternativeRoutes(
        with routes: [RouteInterface],
        completion: @escaping (Result<[RouteAlternative], Error>) -> Void
    ) {
        alternativeRoutesSetupHandler(routes, completion)
    }
}

enum RoutesCoordinatorError: Swift.Error {
    /// `RoutesCoordinator.beginActiveNavigation(with:uuid:completion:)` called while the previous navigation wasn't
    /// ended with `RoutesCoordinator.endActiveNavigation(with:completion:)` method.
    ///
    /// It is most likely a sign of a programmer error in the app code.
    case endingInvalidActiveNavigation
}
