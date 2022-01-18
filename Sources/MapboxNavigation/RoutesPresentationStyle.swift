import Foundation
import MapboxMaps
import MapboxDirections

/**
 A style that will be used when presenting routes on top of a map view by calling
 `NavigationMapView.showcase(_:routesPresentationStyle:animated:)`.
 */
public enum RoutesPresentationStyle {
    
    /**
     Only first route will be presented on a map view.
     
     - parameter cameraOptions: The custom `CameraOptions` that the map view ill be presented with.
     If no value provided, the map view will present the whole first route from above.
     */
    case single(cameraOptions: CameraOptions? = nil)
    
    /**
     All routes will be presented on a map view.
     
     - parameter cameraOptions: The custom `CameraOptions` that the map view ill be presented with.
     If no value provided, the map view will present all routes from above.
     */
    case all(cameraOptions: CameraOptions? = nil)
}
