import Foundation
import CoreLocation
#if os(iOS)
import UIKit
#endif

#if os(iOS)
import UIKit
#endif

/**
 `NavigationLocationManager` is the base location manager which handles permissions and background modes.
 
 If it's necessary to change the default behavior in `NavigationLocationManager`, you can subclass this class.
 */
@objc(MBNavigationLocationManager)
open class NavigationLocationManager: CLLocationManager {
    
    var lastKnownLocation: CLLocation?
    
    override public init() {
        super.init()
        
        requestWhenInUseAuthorization()
        
        desiredAccuracy = UIDevice.current.isPluggedIn ? kCLLocationAccuracyBestForNavigation : kCLLocationAccuracyBest
        
        if #available(iOS 9.0, *) {
            if Bundle.main.backgroundModes.contains("location") {
                allowsBackgroundLocationUpdates = true
            }
        }
    }
}
