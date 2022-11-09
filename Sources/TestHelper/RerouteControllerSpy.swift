import Foundation
import MapboxNavigationNative
@testable import MapboxCoreNavigation

public class RerouteControllerSpy: RerouteController {
    public convenience init() {
        self.init(NativeNavigatorSpy(), config: NativeHandlersFactory.configHandle())
    }

    required init(_ navigator: MapboxNavigationNative.Navigator, config: ConfigHandle) {
        super.init(navigator, config: config)
    }

}
