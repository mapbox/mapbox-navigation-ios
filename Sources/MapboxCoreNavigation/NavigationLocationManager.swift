import Foundation
import CoreLocation
#if os(iOS)
import UIKit
#endif

/**
 `NavigationLocationManager` is the base location manager which handles permissions and background modes.
 */
open class NavigationLocationManager: CLLocationManager {
    override public init() {
        super.init()
        
        requestWhenInUseAuthorization()
        
        if Bundle.main.backgroundModes.contains("location") {
            allowsBackgroundLocationUpdates = true
        }
    }
}

extension NavigationLocationManager: RouterDataSource {
    public var locationProvider: NavigationLocationManager.Type {
        return type(of: self)
    }
}
