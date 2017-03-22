import Foundation

public class NavigationMapView: MGLMapView {
    
    var navigationMapDelegate: NavigationMapViewDelegate?
    
    public override func locationManager(_ manager: CLLocationManager!, didUpdateLocations locations: [Any]!) {
        guard let location = locations.first as? CLLocation else { return }
        
        if let modifiedLocation = navigationMapDelegate?.navigationMapView(self, shouldUpdateTo: location) {
            super.locationManager(manager, didUpdateLocations: [modifiedLocation])
        } else {
            super.locationManager(manager, didUpdateLocations: locations)
        }
    }
}
