import Foundation
import CoreLocation
#if os(iOS)
import UIKit
#endif

#if os(iOS)
import UIKit
#endif

/**
 `NavigationLocationManager` is the base location manager which handles
 permissions and background modes.
 */
@objc(MBNavigationLocationManager)
open class NavigationLocationManager: CLLocationManager {
    
    var lastKnownLocation: CLLocation?
    
    /**
     The accuracy of the `CLLocationManager`.
     */
    @objc public var locationAccuracy: CLLocationAccuracy = kCLLocationAccuracyBestForNavigation
    
    override public init() {
        super.init()
        
        let always = Bundle.main.locationAlwaysUsageDescription
        let both = Bundle.main.locationAlwaysAndWhenInUseUsageDescription
        
        if always != nil || both != nil {
            requestAlwaysAuthorization()
        } else {
            requestWhenInUseAuthorization()
        }
        
        if #available(iOS 9.0, *) {
            if Bundle.main.backgroundModes.contains("location") {
                allowsBackgroundLocationUpdates = true
            }
        }
        
        desiredAccuracy = locationAccuracy
    }
}
