@_implementationOnly import MapboxCommon_Private
import MapboxNavigationNative
@_implementationOnly import MapboxNavigationNative_Private

public class NativeRerouteControllerSpy: RerouteControllerInterface {
    public typealias RerouteCallback = (Expected<RerouteInfo, RerouteError>) -> Void

    public var cancelCalled = false
    public var setOptionsAdapterCalled = false

    public var passedRerouteUrl: String?
    public var passedRerouteCallback: RerouteCallback?
    public var passedRouteOptionsAdapter: RouteOptionsAdapter?

    public func reroute(forUrl url: String, callback: @escaping RerouteCallback) {
        passedRerouteUrl = url
        passedRerouteCallback = callback
    }

    public func cancel() {
        cancelCalled = true
    }

    public func setOptionsAdapterForRouteRequest(_ routeRequestOptionsAdapter: (any RouteOptionsAdapter)?) {
        setOptionsAdapterCalled = true
        passedRouteOptionsAdapter = routeRequestOptionsAdapter
    }
}
