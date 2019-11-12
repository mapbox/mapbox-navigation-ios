import CoreLocation
import MapboxCoreNavigation

public class DummyLocationManager: NavigationLocationManager {
    override public func startUpdatingLocation() {
        // Do nothing
    }
    
    override public func stopUpdatingLocation() {
        // Do nothing
    }
    
    override public func startUpdatingHeading() {
        // Do nothing
    }
    
    override public func stopUpdatingHeading() {
        // Do nothing
    }
}
