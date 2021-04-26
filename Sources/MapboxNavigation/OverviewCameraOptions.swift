import Foundation

/**
 Options, which are used to control what `CameraOptions` parameters will be modified by
 `NavigationViewportDataSource` in `NavigationCameraState.overview` state.
 */
public struct OverviewCameraOptions {
    
    /**
     Maximum zoom, which will be used when producing camera frame in `NavigationCameraState.overview`
     state.
     
     Defaults to `16.35`.
     */
    public var maximumZoom = 16.35
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.center` property
     when producing camera frame in `NavigationCameraState.overview` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.center` property.
     
     Defaults to `true`.
     */
    public var centerUpdatesAllowed = true
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.zoom` property
     when producing camera frame in `NavigationCameraState.overview` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.zoom` property.
     
     Defaults to `true`.
     */
    public var zoomUpdatesAllowed = true
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.bearing` property
     when producing camera frame in `NavigationCameraState.overview` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.bearing` property.
     
     Defaults to `true`.
     */
    public var bearingUpdatesAllowed = true
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.pitch` property
     when producing camera frame in `NavigationCameraState.overview` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.pitch` property.
     
     Defaults to `true`.
     */
    public var pitchUpdatesAllowed = true
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.padding` property
     when producing camera frame in `NavigationCameraState.overview` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.padding` property.
     
     Defaults to `true`.
     */
    public var paddingUpdatesAllowed = true
}
