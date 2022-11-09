import MapboxNavigationNative
@_implementationOnly import MapboxCommon_Private
@_implementationOnly import MapboxNavigationNative_Private

public class RerouteDetectorSpy: RerouteDetectorInterface {
    public typealias ForceRerouteCallback = (Expected<RerouteInfo, RerouteError>) -> Void

    public var forceRerouteCalled = false
    public var returnedIsReroute = false

    public func forceReroute() {
        forceRerouteCalled = true
    }

    public func forceReroute(forCallback callback: @escaping ForceRerouteCallback) {
        forceRerouteCalled = true
    }

    public func isReroute() -> Bool {
        return returnedIsReroute
    }

}
