import UIKit
import CoreLocation
import MapboxNavigation
import MapboxMaps

extension ViewController : StyleManagerDelegate {
    func location(for styleManager: MapboxNavigation.StyleManager) -> CLLocation? {
        if let location = navigationMapView.mapView.location.latestLocation?.location {
            return location
        } else if let location = CLLocationManager.init().location {
            return location
        }
        return nil
    }
    
    func styleManager(_ styleManager: MapboxNavigation.StyleManager, didApply style: MapboxNavigation.Style) {
        updateMapStyle(style)
    }
    
    func updateMapStyle(_ style: MapboxNavigation.Style) {
        if navigationMapView?.mapView.mapboxMap.style.uri?.rawValue != style.mapStyleURL.absoluteString {
            navigationMapView?.mapView.mapboxMap.style.uri = StyleURI(url: style.mapStyleURL)
        }
    }
}
