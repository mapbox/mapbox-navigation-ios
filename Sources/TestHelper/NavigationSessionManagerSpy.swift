import Foundation
@testable import MapboxCoreNavigation

public final class NavigationSessionManagerSpy: NavigationSessionManager {
    public static var shared: NavigationSessionManagerSpy = .init()

    public var reportStartNavigationCalled = false
    public var reportStopNavigationCalled = false

    public func reportStartNavigation() {
        reportStartNavigationCalled = true
    }

    public func reportStopNavigation() {
        reportStopNavigationCalled = true
    }

    public func reset() {
        reportStartNavigationCalled = false
        reportStopNavigationCalled = false
    }
}
