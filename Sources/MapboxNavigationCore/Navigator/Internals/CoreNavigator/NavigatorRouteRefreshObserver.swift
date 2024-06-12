import _MapboxNavigationHelpers
import Foundation
@preconcurrency import MapboxNavigationNative

struct RouteRefreshResult: @unchecked Sendable {
    let updatedRoute: RouteInterface
    let alternativeRoutes: [RouteAlternative]
}

class NavigatorRouteRefreshObserver: RouteRefreshObserver, @unchecked Sendable {
    typealias RefreshCallback = (String, String, UInt32) async -> RouteRefreshResult?
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
        Task {
            guard let routeRefreshResult = await self.refreshCallback(
                routeRefreshResponse,
                "\(routeId)#\(routeIndex)",
                routeGeometryIndex
            ) else {
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
