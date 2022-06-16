import Turf
import MapboxDirections
import MapboxNavigationNative


protocol ReroutingControllerDelegate: AnyObject {
    func rerouteControllerWantsSwitchToAlternative(_ rerouteController: RerouteController,
                                                   response: RouteResponse,
                                                   routeIndex: Int,
                                                   options: RouteOptions,
                                                   routeOrigin: RouterOrigin)
    func rerouteControllerDidDetectReroute(_ rerouteController: RerouteController) -> Bool
    func rerouteControllerDidRecieveReroute(_ rerouteController: RerouteController, response: RouteResponse, options: RouteOptions, routeOrigin: RouterOrigin)
    func rerouteControllerDidCancelReroute(_ rerouteController: RerouteController)
    func rerouteControllerDidFailToReroute(_ rerouteController: RerouteController, with error: DirectionsError)
}

/**
 Error type, describing rerouting process malfunction.
 */
public enum ReroutingError: Error {
    /// Could not correctly process the reroute.
    case routeError
    /// Could not compose correct request for rerouting.
    case wrongRequest
    /// Cause of reroute error is unknown.
    case unknown
    /// Reroute was cancelled by user.
    case cancelled

    init(_ nativeError: RerouteError) {
        switch (nativeError.type) {
        case .routerError:
            self = .routeError
        case .unknown:
            self = .unknown
        case .cancelled:
            self = .cancelled
        @unknown default:
            fatalError("Unknown MapboxNavigationNative.RerouteError value.")
        }
    }
}
