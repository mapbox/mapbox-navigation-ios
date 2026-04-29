import CoreLocation
import MapboxCommon
import MapboxMaps
import MapboxNavigationUIKit
import UIKit

extension ViewController: StyleManagerDelegate {
    func location(for styleManager: MapboxNavigationUIKit.StyleManager) -> CLLocation? {
        navigation.currentLocationMatching?.location
    }

    func styleManager(_ styleManager: MapboxNavigationUIKit.StyleManager, didApply style: MapboxNavigationUIKit.Style) {
        updateMapStyle(style)
    }

    func updateMapStyle(_ style: MapboxNavigationUIKit.Style) {
        if let navigationMapView {
            style.applyMapStyle(to: navigationMapView)
        }
    }
}
