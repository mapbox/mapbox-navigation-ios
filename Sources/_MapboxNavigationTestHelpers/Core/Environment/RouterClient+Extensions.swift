import MapboxCommon
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private

public final class CancellableStub: Cancelable {
    public func cancel() {}
    public init() {}
}

extension RouterClient {
    public static var noopValue: RouterClient {
        Self(
            getRouteForDirectionsUri: { _, _, _, _ in
                return CancellableStub()
            },
            getRouteRefresh: { _, _ in
                return CancellableStub()
            },
            getRouteMapMatchedFor: { _, _, _ in
                return CancellableStub()
            },
            cancelAll: {}
        )
    }
}

extension RouterClient {
    public static var testValue: RouterClient {
        Self(
            getRouteForDirectionsUri: { _, _, _, _ in
                fatalError("not implemented")
            },
            getRouteRefresh: { _, _ in
                fatalError("not implemented")
            },
            getRouteMapMatchedFor: { _, _, _ in
                fatalError("not implemented")
            },
            cancelAll: {
                fatalError("not implemented")
            }
        )
    }
}
