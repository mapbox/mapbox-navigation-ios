import Foundation
import CoreLocation

/**
 `NavigationViewController` is the base location manager which handles
 permissions and background modes.
 */
@objc(MBNavigationLocationManager)
open class NavigationLocationManager: CLLocationManager {
    
    var lastKnownLocation: CLLocation?
    
    override public init() {
        super.init()
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            requestWhenInUseAuthorization()
        }
        
        if Bundle.main.backgroundModeLocationSupported {
            allowsBackgroundLocationUpdates = true
        }
    }
}
