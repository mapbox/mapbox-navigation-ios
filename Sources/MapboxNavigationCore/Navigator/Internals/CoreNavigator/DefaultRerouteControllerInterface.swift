import Foundation
import MapboxNavigationNative_Private

final class DefaultRerouteControllerInterface: RerouteControllerInterface {
    typealias RequestConfiguration = (String) -> String

    let nativeInterface: RerouteControllerInterface?
    let requestConfig: RequestConfiguration?
    let routeOptionsAdapter: RouteOptionsAdapter?

    init(
        nativeInterface: RerouteControllerInterface?,
        requestConfig: RequestConfiguration? = nil
    ) {
        self.nativeInterface = nativeInterface
        self.requestConfig = requestConfig
        self.routeOptionsAdapter = nil
    }

    init(
        nativeInterface: RerouteControllerInterface?,
        routeOptionsAdapter: RouteOptionsAdapter? = nil
    ) {
        self.nativeInterface = nativeInterface
        self.requestConfig = nil
        self.routeOptionsAdapter = routeOptionsAdapter
        if let routeOptionsAdapter {
            setOptionsAdapterForRouteRequest(routeOptionsAdapter)
        }
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
