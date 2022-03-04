import Turf
import MapboxDirections
import MapboxNavigationNative


protocol ReroutingObserverDelegate: AnyObject {
    func rerouteControllerWantsSwitchToAlternative(_ rerouteController: RerouteController, response: RouteResponse, options: RouteOptions)
    func rerouteControllerDidDetectReroute(_ rerouteController: RerouteController)
    func rerouteControllerDidRecieveReroute(_ rerouteController: RerouteController, response: RouteResponse, options: RouteOptions)
    func rerouteControllerDidCancelReroute(_ rerouteController: RerouteController)
    func rerouteControllerDidFailToReroute(_ rerouteController: RerouteController, with error: ReroutingError)
}

/**
 Error type, describing rerouting process malfunction.
 */
public enum ReroutingError: Error {
    case routeError
    case wrongRequest
    case cancelled
    case decodingError
    
    init( _ nativeError: RerouteError) {
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
