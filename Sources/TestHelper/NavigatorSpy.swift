import MapboxNavigationNative
@testable import MapboxCoreNavigation

public class NavigatorSpy: MapboxCoreNavigation.Navigator {
    public var returnedMostRecentNavigationStatus: NavigationStatus?

    public override var mostRecentNavigationStatus: NavigationStatus? {
        return returnedMostRecentNavigationStatus
    }

    public var returnedNavigator: MapboxNavigationNative.Navigator = NativeNavigatorSpy()

    public override var navigator: MapboxNavigationNative.Navigator {
        return returnedNavigator
    }
    
}
