import Foundation
import MapboxMaps

/**
 A style that will be used when presenting routes on top of a map view by calling
 `NavigationMapView.showcase(_:routesPresentationStyle:animated:)`.
 */
public enum RoutesPresentationStyle {
    
    /**
     Only first route will be presented on a map view.
     
     - parameter cameraOptions: The custom `CameraOptions` that the map view will use while presenting a single route.
     If no value was provided, the map view will use default `CameraOptions` value, which is based on current safe area.
     */
    case single(cameraOptions: CameraOptions? = nil)
    
    /**
     All routes will be presented on a map view.
     
     - parameter shouldFit: If `true` geometry of all routes will be used for camera transition.
     If `false` geometry of only first route will be used. Defaults to `true`.
     - parameter cameraOptions: The custom `CameraOptions` that the map view will use while presenting all routes.
     If no value was provided, the map view will use default `CameraOptions` value, which is based on current safe area.
     */
    case all(shouldFit: Bool = true, cameraOptions: CameraOptions? = nil)
}
