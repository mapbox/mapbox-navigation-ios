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
     Indicates whether the device is plugged in or not.
     */
    public private(set) var isPluggedIn: Bool = false
    
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
        
        #if os(iOS)
            guard automaticallyUpdatesDesiredAccuracy else { return }
            let _ = UIDevice.current.observe(\.batteryState) { [weak self] (device, changed) in
                guard let weakSelf = self else { return }
                weakSelf.isPluggedIn = device.batteryState == .charging || device.batteryState == .full
                weakSelf.desiredAccuracy = weakSelf.isPluggedIn ? kCLLocationAccuracyBestForNavigation : kCLLocationAccuracyBest
            }
        #endif
    }
}
