import Foundation
import MapboxNavigationNative

protocol NavigationSessionManager {
    func reportStartNavigation()
    func reportStopNavigation()
}

final class NavigationSessionManagerImp: NavigationSessionManager {
    private let lock: NSLock = .init()

    private var sessionCount: Int

    private let navigator: NavigationNativeNavigator

    init(navigator: NavigationNativeNavigator, previousSession: NavigationSessionManagerImp? = nil) {
        self.navigator = navigator
        self.sessionCount = previousSession?.sessionCount ?? 0
    }

    func reportStartNavigation() {
        var shouldStart = false
        lock {
            shouldStart = sessionCount == 0
            sessionCount += 1
        }
        if shouldStart {
            navigator.startNavigationSession()
        }
    }

    func reportStopNavigation() {
        var shouldStop = false
        lock {
            shouldStop = sessionCount == 1
            sessionCount = max(sessionCount - 1, 0)
        }
        if shouldStop {
            navigator.stopNavigationSession()
        }
    }
}
