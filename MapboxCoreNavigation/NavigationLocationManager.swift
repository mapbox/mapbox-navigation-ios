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
     Indicates whether the location manager’s desired accuracy should update
     when the battery state changes.
     */
    public var automaticallyUpdatesDesiredAccuracy = true
    
    override public init() {
        super.init()
        
        requestWhenInUseAuthorization()
        
        if #available(iOS 9.0, *) {
            if Bundle.main.backgroundModes.contains("location") {
                allowsBackgroundLocationUpdates = true
            }
        }
        
        desiredAccuracy = kCLLocationAccuracyBest
        
        guard automaticallyUpdatesDesiredAccuracy else { return }
        desiredAccuracy = UIDevice.current.isPluggedIn ? kCLLocationAccuracyBestForNavigation : kCLLocationAccuracyBest
    }
}
