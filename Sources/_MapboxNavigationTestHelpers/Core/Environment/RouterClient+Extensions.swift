@testable import MapboxNavigationCore
@_implementationOnly import MapboxNavigationNative_Private

extension RouterClient {
    public static var noopValue: RouterClient {
        Self(
            getRouteForDirectionsUri: { _, _, _, _ in
                return 0
            },
            getRouteRefresh: { _, _ in
                return 0
            },
            getRouteMapMatchedFor: { _, _, _ in
                return 0
            },
            cancelRouteRequest: { _ in },
            cancelRouteRefreshRequest: { _ in },
            cancelRouteMapMatchedRequest: { _ in },
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
            cancelRouteRequest: { _ in
                fatalError("not implemented")
            },
            cancelRouteRefreshRequest: { _ in
                fatalError("not implemented")
            },
            cancelRouteMapMatchedRequest: { _ in
                fatalError("not implemented")
            },
            cancelAll: {
                fatalError("not implemented")
            }
        )
    }
}
