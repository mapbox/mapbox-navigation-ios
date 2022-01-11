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
     */
    case single
    
    /**
     All routes will be presented on a map view.
     
     - parameter shouldFit: If `true` geometry of all routes will be used for camera transition.
     If `false` geometry of only first route will be used. Defaults to `true`.
     */
    case all(shouldFit: Bool = true)
    
    /**
     The custom routes will be presented on a map view with the custom camera options.
     
     - parameter routes: The custom `Routes` that will be presented on a map view.
     - parameter cameraOptions: The custom `CameraOptions` that the map view ill be presented with.
     */
    case custom(routes: [Route]? = nil, cameraOptions: CameraOptions? = nil)
}
