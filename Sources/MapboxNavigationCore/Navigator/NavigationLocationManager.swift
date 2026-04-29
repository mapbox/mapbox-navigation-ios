import CoreLocation
import Foundation
#if os(iOS)
import UIKit
#endif

/// ``NavigationLocationManager`` is the base location manager which handles permissions and background modes.
open class NavigationLocationManager: CLLocationManager {
    @MainActor
    override public init() {
        super.init()

        requestWhenInUseAuthorization()

        if Bundle.main.backgroundModes.contains("location") {
            allowsBackgroundLocationUpdates = true
        }

        delegate = self
    }

    /// Indicates whether the location manager is providing simulated locations.
    open var simulatesLocation: Bool = false

    public weak var locationDelegate: NavigationLocationManagerDelegate? = nil
}

public protocol NavigationLocationManagerDelegate: AnyObject {
    func navigationLocationManager(
        _ locationManager: NavigationLocationManager,
        didReceiveNewLocation location: CLLocation
    )
}

extension NavigationLocationManager: CLLocationManagerDelegate {
    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            locationDelegate?.navigationLocationManager(
                self,
                didReceiveNewLocation: location
            )
        }
    }
}
