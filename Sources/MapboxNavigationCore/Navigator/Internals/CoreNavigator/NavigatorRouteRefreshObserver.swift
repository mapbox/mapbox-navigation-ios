import _MapboxNavigationHelpers
import Foundation
@preconcurrency import MapboxNavigationNative_Private

enum RouteRefreshResult: @unchecked Sendable {
    case mainRoute(RouteInterface)
    case alternativeRoute(alternative: RouteAlternative)
}

class NavigatorRouteRefreshObserver: RouteRefreshObserver, @unchecked Sendable {
    typealias RefreshCallback = (String) -> RouteRefreshResult?
    private var refreshCallback: RefreshCallback

    init(refreshCallback: @escaping RefreshCallback) {
        self.refreshCallback = refreshCallback
    }

    func onRouteRefreshAnnotationsUpdated(
        for routeIdentifier: RouteIdentifier,
        routeRefreshResponse: String,
        legIndex: UInt32,
        routeGeometryIndex: UInt32
    ) {
        let routeId = routeIdentifier.toRouteIdString()
        let routeIndex = routeIdentifier.index
        guard let routeRefreshResult = refreshCallback(routeId) else {
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

    func onRouteRefreshCancelled(for routeIdentifier: RouteIdentifier) {
        let userInfo: [NativeNavigator.NotificationUserInfoKey: any Sendable] = [
            .refreshRequestIdKey: routeIdentifier.toRouteIdString(),
        ]
        onMainAsync {
            NotificationCenter.default.post(name: .routeRefreshDidCancelRefresh, object: nil, userInfo: userInfo)
        }
    }

    func onRouteRefreshFailed(for routeIdentifier: RouteIdentifier, error: RouteRefreshError) {
        let userInfo: [NativeNavigator.NotificationUserInfoKey: any Sendable] = [
            .refreshRequestErrorKey: error,
            .refreshRequestIdKey: routeIdentifier.toRouteIdString(),
        ]
        onMainAsync {
            NotificationCenter.default.post(name: .routeRefreshDidFailRefresh, object: nil, userInfo: userInfo)
        }
    }
}
