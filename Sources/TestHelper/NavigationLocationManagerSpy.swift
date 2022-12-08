import CoreLocation
import MapboxCoreNavigation

public class NavigationLocationManagerSpy: NavigationLocationManager {
    public var startUpdatingLocationCalled = false
    public var stopUpdatingLocationCalled = false
    public var startUpdatingHeadingCalled = false
    public var stopUpdatingHeadingCalled = false
    public var requestLocationCalled = false

    public var returnedLocation: CLLocation?

    public override var location: CLLocation? {
        return returnedLocation
    }

    public override func stopUpdatingLocation() {
        stopUpdatingLocationCalled = true
    }

    public override func startUpdatingLocation() {
        startUpdatingLocationCalled = true
    }

    public override func stopUpdatingHeading() {
        stopUpdatingHeadingCalled = true
    }

    public override func startUpdatingHeading() {
        startUpdatingHeadingCalled = true
    }

    public override func requestLocation() {
        requestLocationCalled = true
    }
    
}
