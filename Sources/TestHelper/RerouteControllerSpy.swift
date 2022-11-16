import Foundation
import MapboxNavigationNative
@testable import MapboxCoreNavigation

public final class RerouteControllerSpy: RerouteController {
    public var returnedUserIsOnRoute = true
    public var forceRerouteCalled = false

    public convenience init() {
        self.init(NativeNavigatorSpy(), config: NativeHandlersFactory.configHandle())
    }

    required init(_ navigator: MapboxNavigationNative.Navigator, config: ConfigHandle) {
        super.init(navigator, config: config)
    }

    public override func userIsOnRoute() -> Bool {
        return returnedUserIsOnRoute
    }

    public override func forceReroute() {
        forceRerouteCalled = true
    }

}
