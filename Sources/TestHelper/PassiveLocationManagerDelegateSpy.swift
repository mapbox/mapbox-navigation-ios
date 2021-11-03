import Foundation
import CoreLocation
import MapboxCoreNavigation

public final class PassiveLocationManagerDelegateSpy: PassiveLocationManagerDelegate {
    public var onProgressUpdate: (() -> Void)?

    public init() {}

    public func passiveLocationManager(_ manager: PassiveLocationManager,
                                didUpdateLocation location: CLLocation,
                                rawLocation: CLLocation) {
        onProgressUpdate?()
    }

    public func passiveLocationManagerDidChangeAuthorization(_ manager: PassiveLocationManager) {}
    public func passiveLocationManager(_ manager: PassiveLocationManager, didUpdateHeading newHeading: CLHeading) {}
    public func passiveLocationManager(_ manager: PassiveLocationManager, didFailWithError error: Error) {}
}
