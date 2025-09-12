import MapboxDirections
import MapboxNavigationNative_Private
import Turf

protocol ReroutingControllerDelegate: AnyObject {
    func rerouteControllerWantsSwitchToAlternative(
        _ rerouteController: RerouteController,
        route: RouteInterface,
        legIndex: Int
    )
    func rerouteControllerDidDetectReroute(_ rerouteController: RerouteController)
    func rerouteControllerDidReceiveReroute(_ rerouteController: RerouteController, routesData: RoutesData)
    func rerouteControllerDidCancelReroute(_ rerouteController: RerouteController)
    func rerouteControllerDidFailToReroute(_ rerouteController: RerouteController, with error: DirectionsError)
    func rerouteController(_ rerouteController: RerouteController, willModify requestString: String) -> RouteOptions?
}

/// Error type, describing rerouting process malfunction.
public enum ReroutingError: Error {
    /// Could not correctly process the reroute.
    case routeError
    /// Could not compose correct request for rerouting.
    case wrongRequest
    /// Cause of reroute error is unknown.
    case unknown
    /// Reroute was cancelled by user.
    case cancelled
    /// No routes or reroute controller was set to Navigator
    case noRoutesOrController
    /// Another reroute is in progress.
    case anotherRerouteInProgress

    init?(_ nativeError: RerouteError) {
        switch nativeError.type {
        case .routerError:
            self = .routeError
        case .unknown:
            self = .unknown
        case .cancelled:
            self = .cancelled
        case .noRoutesOrController:
            self = .noRoutesOrController
        case .buildUriError:
            self = .wrongRequest
        case .rerouteInProgress:
            self = .anotherRerouteInProgress
        @unknown default:
            assertionFailure("Unknown MapboxNavigationNative_Private.RerouteError value.")
            return nil
        }
    }
}
