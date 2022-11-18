import Foundation
import CoreLocation
import MapboxCoreNavigation

public final class PassiveLocationManagerDelegateSpy: PassiveLocationManagerDelegate {
    public var onProgressUpdate: ((CLLocation, CLLocation) -> Void)?
    public var onHeadingUpdate: ((CLHeading) -> Void)?
    public var onError: ((Error) -> Void)?
    public var onAuthorizationChange: (() -> Void)?

    public init() {}

    public func passiveLocationManager(_ manager: PassiveLocationManager,
                                       didUpdateLocation location: CLLocation,
                                       rawLocation: CLLocation) {
        onProgressUpdate?(location, rawLocation)
    }

    public func passiveLocationManagerDidChangeAuthorization(_ manager: PassiveLocationManager) {
        onAuthorizationChange?()
    }

    public func passiveLocationManager(_ manager: PassiveLocationManager, didUpdateHeading newHeading: CLHeading) {
        onHeadingUpdate?(newHeading)
    }

    public func passiveLocationManager(_ manager: PassiveLocationManager, didFailWithError error: Error) {
        onError?(error)
    }
}
