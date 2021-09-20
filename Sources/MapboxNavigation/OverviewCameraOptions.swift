import Foundation

/**
 Options, which are used to control what `CameraOptions` parameters will be modified by
 `NavigationViewportDataSource` in `NavigationCameraState.overview` state.
 */
public struct OverviewCameraOptions: Equatable {
    
    /**
     Maximum zoom level, which will be used when producing camera frame in `NavigationCameraState.overview`
     state.
     
     Defaults to `16.35`.

     - Invariant: Acceptable range of values is 0...22.
     */
    public var maximumZoomLevel: Double = 16.35 {
        didSet {
            if maximumZoomLevel < 0.0 {
                maximumZoomLevel = 0
                assertionFailure("Maximum zoom level should not be lower than 0.0")
            }
            
            if maximumZoomLevel > 22.0 {
                maximumZoomLevel = 22
                assertionFailure("Maximum zoom level should not be higher than 22.0")
            }
        }
    }
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.center` property
     when producing camera frame in `NavigationCameraState.overview` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.center` property.
     
     Defaults to `true`.
     */
    public var centerUpdatesAllowed: Bool = true
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.zoom` property
     when producing camera frame in `NavigationCameraState.overview` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.zoom` property.
     
     Defaults to `true`.
     */
    public var zoomUpdatesAllowed: Bool = true
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.bearing` property
     when producing camera frame in `NavigationCameraState.overview` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.bearing` property.
     
     Defaults to `true`.
     */
    public var bearingUpdatesAllowed: Bool = true
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.pitch` property
     when producing camera frame in `NavigationCameraState.overview` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.pitch` property.
     
     Defaults to `true`.
     */
    public var pitchUpdatesAllowed: Bool = true
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.padding` property
     when producing camera frame in `NavigationCameraState.overview` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.padding` property.
     
     Defaults to `true`.
     */
    public var paddingUpdatesAllowed: Bool = true
    
    /**
     Initializes `OverviewCameraOptions` instance.
     */
    public init() {
        // No-op
    }
    
    public static func == (lhs: OverviewCameraOptions, rhs: OverviewCameraOptions) -> Bool {
        return lhs.maximumZoomLevel == rhs.maximumZoomLevel &&
            lhs.zoomUpdatesAllowed == rhs.zoomUpdatesAllowed &&
            lhs.bearingUpdatesAllowed == rhs.bearingUpdatesAllowed &&
            lhs.pitchUpdatesAllowed == rhs.pitchUpdatesAllowed &&
            lhs.paddingUpdatesAllowed == rhs.paddingUpdatesAllowed
    }
}
