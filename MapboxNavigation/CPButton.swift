import Foundation
import CarPlay

@available(iOS 12.0, *)
extension CPMapButton {
    
    public static func zoomInButton(for mapView: MGLMapView) -> CPMapButton {
        let zoomInButton = CPMapButton { (button) in
            mapView.setZoomLevel(mapView.zoomLevel + 1, animated: true)
        }
        zoomInButton.image = Bundle.mapboxNavigation.image(named: "plus")!
        return zoomInButton
    }
    
    public static func zoomOutButton(for mapView: MGLMapView) -> CPMapButton {
        let zoomInButton = CPMapButton { (button) in
            mapView.setZoomLevel(mapView.zoomLevel - 1, animated: true)
        }
        zoomInButton.image = Bundle.mapboxNavigation.image(named: "minus")!
        return zoomInButton
    }
}

@available(iOS 12.0, *)
extension CPBarButton {
    
    public static func panButton(for mapView: MGLMapView, mapTemplate: CPMapTemplate) -> CPBarButton {
        let panButton = CPBarButton(type: .text) { (button) in
            if mapTemplate.isPanningInterfaceVisible {
                button.title = "Pan map"
                mapTemplate.dismissPanningInterface(animated: true)
                mapView.userTrackingMode = .follow
            } else {
                button.title = "Dismiss"
                mapTemplate.showPanningInterface(animated: true)
            }
        }
        
        panButton.title = "Pan map"
        
        return panButton
    }
}
