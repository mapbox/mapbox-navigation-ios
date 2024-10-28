@_implementationOnly import MapboxCommon_Private
import MapboxNavigationNative
@_implementationOnly import MapboxNavigationNative_Private

public class RerouteDetectorSpy: RerouteDetectorInterface {
    public typealias ForceRerouteCallback = (Expected<RerouteInfo, RerouteError>) -> Void

    public var forceRerouteCalled = false
    public var cancelRerouteCalled = false
    public var returnedIsReroute = false

    public func forceReroute(for reason: ForceRerouteReason) {
        forceRerouteCalled = true
    }

    public func forceReroute(for reason: ForceRerouteReason, callback: @escaping ForceRerouteCallback) {
        forceRerouteCalled = true
    }

    public func isReroute() -> Bool {
        returnedIsReroute
    }

    public func cancelReroute() {
        cancelRerouteCalled = true
    }
}
