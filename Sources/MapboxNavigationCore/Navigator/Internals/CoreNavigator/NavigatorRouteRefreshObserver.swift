import _MapboxNavigationHelpers
import Foundation
@preconcurrency import MapboxNavigationNative_Private

enum RouteRefreshResult: @unchecked Sendable {
    case mainRoute(RouteInterface)
    case alternativeRoute(alternative: RouteAlternative)
}

class NavigatorRouteRefreshObserver: RouteRefreshObserver, @unchecked Sendable {
    typealias RefreshCallback = (String, UInt32, UInt32) -> RouteRefreshResult?
    private var refreshCallback: RefreshCallback

    init(refreshCallback: @escaping RefreshCallback) {
        self.refreshCallback = refreshCallback
    }

    func onRouteRefreshAnnotationsUpdated(
        forRouteId routeId: String,
        routeRefreshResponse: String,
        routeIndex: UInt32,
        legIndex: UInt32,
        routeGeometryIndex: UInt32
    ) {
        guard let routeRefreshResult = refreshCallback(routeId, routeIndex, legIndex) else {
            return
        }

        let userInfo: [NativeNavigator.NotificationUserInfoKey: any Sendable] = [
            .refreshRequestIdKey: routeId,
            .refreshedRoutesResultKey: routeRefreshResult,
            .legIndexKey: legIndex,
        ]

        onMainAsync {
            NotificationCenter.default.post(
                name: .routeRefreshDidUpdateAnnotations,
                object: nil,
                userInfo: userInfo
            )
        }
    }

    func onRouteRefreshCancelled(forRouteId routeId: String) {
        let userInfo: [NativeNavigator.NotificationUserInfoKey: any Sendable] = [
            .refreshRequestIdKey: routeId,
        ]
        onMainAsync {
            NotificationCenter.default.post(name: .routeRefreshDidCancelRefresh, object: nil, userInfo: userInfo)
        }
    }

    func onRouteRefreshFailed(forRouteId routeId: String, error: RouteRefreshError) {
        let userInfo: [NativeNavigator.NotificationUserInfoKey: any Sendable] = [
            .refreshRequestErrorKey: error,
            .refreshRequestIdKey: routeId,
        ]
        onMainAsync {
            NotificationCenter.default.post(name: .routeRefreshDidFailRefresh, object: nil, userInfo: userInfo)
        }
    }
}
