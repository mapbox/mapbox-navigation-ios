import Foundation
import MapboxNavigationNative

protocol NavigationSessionManager {
    static var shared: Self { get }

    func reportStartNavigation()
    func reportStopNavigation()
}

final class NavigationSessionManagerImp: NavigationSessionManager {
    private let lock: NSLock = .init()

    private var sessionCount: Int = 0

    private let navigatorType: CoreNavigator.Type

    private var navigator: MapboxNavigationNative.Navigator {
        return navigatorType.shared.navigator
    }

    func reportStartNavigation() {
        guard NavigationTelemetryConfiguration.useNavNativeTelemetryEvents else { return }

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
        guard NavigationTelemetryConfiguration.useNavNativeTelemetryEvents else { return }

        var shouldStop = false
        lock {
            shouldStop = sessionCount == 1
            sessionCount = max(sessionCount - 1, 0)
        }
        if shouldStop {
            navigator.stopNavigationSession()
        }
    }

    /// Shared manager instance. There is no other instances of `NavigationSessionManager`.
    static let shared: NavigationSessionManagerImp = .init()

    init(navigatorType: CoreNavigator.Type = Navigator.self) {
        self.navigatorType = navigatorType
    }
}
