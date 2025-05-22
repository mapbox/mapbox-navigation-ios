import Foundation
import MapboxNavigationNative

class NavigatorStatusObserver: NavigatorObserver {
    func onPrimaryRouteChanged(
        forPrimaryRoute primaryRoute: (any RouteInterface)?,
        reason: PrimaryRouteChangeReason
    ) {
        // Intentionally left empty.
    }

    func onAlternativeRoutesChanged(
        forAlternativeRoutes alternativeRoutes: [RouteAlternative],
        reason: AlternativeRoutesChangeReason
    ) {
        // Intentionally left empty. RouteAlternativesObserver is used instead.
    }

    var mostRecentNavigationStatus: NavigationStatus? = nil

    func onStatus(for origin: NavigationStatusOrigin, status: NavigationStatus) {
        assert(Thread.isMainThread)

        let userInfo: [NativeNavigator.NotificationUserInfoKey: Any] = [
            .originKey: origin,
            .statusKey: status,
        ]
        NotificationCenter.default.post(name: .navigationStatusDidChange, object: nil, userInfo: userInfo)

        mostRecentNavigationStatus = status
    }
}
