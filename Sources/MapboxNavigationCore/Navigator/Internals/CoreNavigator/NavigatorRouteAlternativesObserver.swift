import Foundation
import MapboxNavigationNative_Private

class NavigatorRouteAlternativesObserver: RouteAlternativesObserver {
    func onRouteAlternativesUpdated(
        forOnlinePrimaryRoute onlinePrimaryRoute: RouteInterface?,
        alternatives: [RouteAlternative],
        removedAlternatives: [RouteAlternative]
    ) {
        // do nothing
    }

    func onRouteAlternativesChanged(for routeAlternatives: [RouteAlternative], removed: [RouteAlternative]) {
        let userInfo: [NativeNavigator.NotificationUserInfoKey: Any] = [
            .alternativesListKey: routeAlternatives,
            .removedAlternativesKey: removed,
        ]
        NotificationCenter.default.post(name: .navigatorDidChangeAlternativeRoutes, object: nil, userInfo: userInfo)
    }

    func onError(forMessage message: String) {
        let userInfo: [NativeNavigator.NotificationUserInfoKey: Any] = [
            .messageKey: message,
        ]
        NotificationCenter.default.post(
            name: .navigatorDidFailToChangeAlternativeRoutes,
            object: nil,
            userInfo: userInfo
        )
    }

    func onOnlinePrimaryRouteAvailable(forOnlinePrimaryRoute onlinePrimaryRoute: RouteInterface) {
        let userInfo: [NativeNavigator.NotificationUserInfoKey: Any] = [
            .coincideOnlineRouteKey: onlinePrimaryRoute,
        ]
        NotificationCenter.default.post(
            name: .navigatorWantsSwitchToCoincideOnlineRoute,
            object: nil,
            userInfo: userInfo
        )
    }
}
