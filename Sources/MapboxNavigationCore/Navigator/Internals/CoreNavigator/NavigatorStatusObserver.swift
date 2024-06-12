import Foundation
import MapboxNavigationNative

class NavigatorStatusObserver: NavigatorObserver {
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
