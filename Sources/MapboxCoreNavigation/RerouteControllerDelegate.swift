import Turf
import MapboxDirections
import MapboxNavigationNative


protocol ReroutingControllerDelegate: AnyObject {
    // TODO: fill with Native RerouteController and Alternative routes integration
    func rerouteControllerDidDetectReroute(_ rerouteController: RerouteController)
    func rerouteControllerDidRecieveReroute(_ rerouteController: RerouteController, response: RouteResponse, options: RouteOptions)
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
    /// Reroute was cancelled by user.
    case cancelled

    init(_ nativeError: RerouteError) {
        switch (nativeError.type) {
        case .routerError:
            self = .routeError
        case .wrongRequest:
            self = .wrongRequest
        case .cancelled:
            self = .cancelled
        @unknown default:
            fatalError("Unknown MapboxNavigationNative.RerouteError value.")
        }
    }
}
