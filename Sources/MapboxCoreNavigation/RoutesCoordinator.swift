import Foundation
import MapboxNavigationNative

/// Coordinating routes update to NavNative Navigator to rule out some edge scenarios.
final class RoutesCoordinator {
    private enum State {
        case passiveNavigation
        case activeNavigation(UUID)
    }

    typealias RoutesResult = (mainRouteInfo: RouteInfo?, alternativeRoutes: [RouteAlternative])
    typealias RoutesSetupHandler = (_ mainRoute: RouteInterface?, _ legIndex: UInt32, _ alternativeRoutes: [RouteInterface], _ completion: @escaping (Result<RoutesResult, Error>) -> Void) -> Void
    typealias AlternativeRoutesSetupHandler = (_ routes: [RouteInterface], _ completion: @escaping (Result<[RouteAlternative], Error>) -> Void) -> Void

    private struct ActiveNavigationSession {
        let uuid: UUID
    }

    private let routesSetupHandler: RoutesSetupHandler
    private let alternativeRoutesSetupHandler: AlternativeRoutesSetupHandler
    /// The lock that protects mutable state in `RoutesCoordinator`.
    private let lock: NSLock
    private var state: State
    
    /// Create a new coordinator that will coordinate  requests to set main and alternative routes.
    /// - Parameter routesSetupHandler: The handler that passes main and alternative route's`RouteInterface` objects to underlying Navigator.
    /// - Parameter alternativeRoutesSetupHandler: The handler that passes only alternative route's`RouteInterface` objects to underlying Navigator. Main route must be set before and it will remain unchanged.
    init(routesSetupHandler: @escaping RoutesSetupHandler, alternativeRoutesSetupHandler: @escaping AlternativeRoutesSetupHandler) {
        self.routesSetupHandler = routesSetupHandler
        self.alternativeRoutesSetupHandler = alternativeRoutesSetupHandler
        lock = .init()
        state = .passiveNavigation
    }


    /// - Parameters:
    ///   - uuid: The UUID of the current active guidances session. All reroutes should have the same uuid.
    ///   - legIndex: The index of the leg along which to begin navigating.
    func beginActiveNavigation(with route: RouteInterface,
                               uuid: UUID,
                               legIndex: UInt32,
                               alternativeRoutes: [RouteInterface],
                               completion: @escaping (Result<RoutesResult, Error>) -> Void) {
        lock.lock()
        if case .activeNavigation(let currentUUID) = state, currentUUID != uuid {
            Log.fault("[BUG] Two simultaneous active navigation sessions. This might happen if there are two NavigationViewController or RouteController instances exists at the same time. Profile the app and make sure that NavigationViewController is deallocated once not in use.", category: .navigation)
        }

        state = .activeNavigation(uuid)
        lock.unlock()

        routesSetupHandler(route, legIndex, alternativeRoutes, completion)
    }

    /// - Parameters:
    ///   - uuid: The UUID that was passed to `RoutesCoordinator.beginActiveNavigation(with:uuid:completion:)` method.
    func endActiveNavigation(with uuid: UUID, completion: @escaping (Result<RoutesResult, Error>) -> Void) {
        lock.lock()
        guard case .activeNavigation(let currentUUID) = state, currentUUID == uuid else {
            lock.unlock()
            completion(.failure(RoutesCoordinatorError.endingInvalidActiveNavigation))
            return
        }
        state = .passiveNavigation
        lock.unlock()
        // TODO: Is it safe to set the leg index to 0 when unsetting a route?
        routesSetupHandler(nil, 0, [], completion)
    }
    
    func updateAlternativeRoutes(with routes: [RouteInterface], completion: @escaping (Result<[RouteAlternative], Error>) -> Void) {
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
