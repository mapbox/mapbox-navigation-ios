import Foundation
import MapboxNavigationNative_Private

class DefaultRerouteControllerInterface: RerouteControllerInterface {
    typealias RequestConfiguration = (String) -> String

    let nativeInterface: RerouteControllerInterface?
    let requestConfig: RequestConfiguration?

    init(
        nativeInterface: RerouteControllerInterface?,
        requestConfig: RequestConfiguration? = nil
    ) {
        self.nativeInterface = nativeInterface
        self.requestConfig = requestConfig
    }

    func reroute(forUrl url: String, callback: @escaping RerouteCallback) {
        nativeInterface?.reroute(forUrl: requestConfig?(url) ?? url, callback: callback)
    }

    func cancel() {
        nativeInterface?.cancel()
    }

    func setOptionsAdapterForRouteRequest(_ routeRequestOptionsAdapter: (any RouteOptionsAdapter)?) {
        nativeInterface?.setOptionsAdapterForRouteRequest(routeRequestOptionsAdapter)
    }
}
