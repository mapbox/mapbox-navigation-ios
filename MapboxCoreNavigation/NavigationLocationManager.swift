import Foundation
import CoreLocation
#if os(iOS)
import UIKit
#endif

/**
 `NavigationLocationManager` is the base location manager which handles permissions and background modes.
 */
@objc(MBNavigationLocationManager)
open class NavigationLocationManager: CLLocationManager, NSCopying {
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = NavigationLocationManager()
        copy.lastKnownLocation = lastKnownLocation
        return copy
    }
    
    
    var lastKnownLocation: CLLocation?
    
    override public init() {
        super.init()
        
        requestWhenInUseAuthorization()
        
        if Bundle.main.backgroundModes.contains("location") {
            allowsBackgroundLocationUpdates = true
        }
    }
}
