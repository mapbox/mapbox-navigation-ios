import Foundation
import CoreLocation
#if os(iOS)
    import UIKit
#endif

#if os(iOS)
    import UIKit
#endif


extension UIDevice {
    
    /**
     Returns a `Bool` whether the device is plugged in. Returns false if not an iOS device.
     */
    @objc public var isPluggedIn: Bool {
        #if os(iOS)
            return [.charging, .full].contains(UIDevice.current.batteryState)
        #else
            return false
        #endif
    }
}
