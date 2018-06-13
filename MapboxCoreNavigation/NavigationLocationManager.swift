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
    @available(*, deprecated, message: "Manually override desiredAccuracy instead.")
    public var automaticallyUpdatesDesiredAccuracy = true
    
    var accuracyOverride: CLLocationAccuracy?
    
    override open var desiredAccuracy: CLLocationAccuracy {
        get {
            if let override = accuracyOverride { return override }
            return  UIDevice.current.isPluggedIn ? kCLLocationAccuracyBestForNavigation : kCLLocationAccuracyBest
        }
        set {
            accuracyOverride = newValue
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
