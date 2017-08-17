import Foundation
import CoreLocation

#if os(iOS)
import UIKit
#endif

/**
 `NavigationViewController` is the base location manager which handles
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
        
        desiredAccuracy = kCLLocationAccuracyBest
        
        #if os(iOS)
            UIDevice.current.addObserver(self, forKeyPath: "batteryState", options: [.initial, .new], context: nil)
        #endif
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "batteryState" {
            let batteryState = UIDevice.current.batteryState
            isPluggedIn = batteryState == .charging || batteryState == .full
            
            guard automaticallyUpdatesDesiredAccuracy else { return }
            desiredAccuracy = isPluggedIn ? kCLLocationAccuracyBestForNavigation : kCLLocationAccuracyBest
        }
    }
    
    deinit {
        #if os(iOS)
            UIDevice.current.removeObserver(self, forKeyPath: "batteryState")
        #endif
    }
}
