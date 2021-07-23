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
    
    /**
     `simulatesLocation` used to indicate whether the location manager is providing simulated locations.
     - seealso: `NavigationMapView.simulatesLocation`
     */
    public var simulatesLocation: Bool = false
}

extension NavigationLocationManager: RouterDataSource {
    public var locationManagerType: NavigationLocationManager.Type {
        return type(of: self)
    }
}
