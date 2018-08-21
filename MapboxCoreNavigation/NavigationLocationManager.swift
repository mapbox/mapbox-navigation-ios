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
 */
@objc(MBNavigationLocationManager)
open class NavigationLocationManager: CLLocationManager {
    
    override open var delegate: CLLocationManagerDelegate? {
        get {
            return super.delegate
        }
        set {
            super.delegate = newValue
        }
    }
    
    override public init() {
        super.init()
        
        requestWhenInUseAuthorization()
        
        if Bundle.main.backgroundModes.contains("location") {
            allowsBackgroundLocationUpdates = true
        }
    }
}
