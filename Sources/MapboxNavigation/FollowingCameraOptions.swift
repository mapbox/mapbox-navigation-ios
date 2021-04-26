import CoreLocation

/**
 Options, which are used to control what `CameraOptions` parameters will be modified by
 `NavigationViewportDataSource` in `NavigationCameraState.following` state.
 */
public struct FollowingCameraOptions {
    
    /**
     Pitch, which will be taken into account when preparing `CameraOptions` during active guidance
     navigation.
     
     Defaults to `45.0` degrees.
     */
    public var defaultPitch: Double = 45.0
    
    /**
     Maximum zoom, which will be used when producing camera frame in `NavigationCameraState.following`
     state.
     
     Defaults to `16.35`.
     */
    public var maximumZoom: Double = 16.35
    
    /**
     Altitude that the `NavigationCamera` initally defaults to when active guidance navigation starts.
     
     Defaults to `1000.0` meters.
     */
    public var initialAltitude: CLLocationDistance = 1000.0
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.center` property
     when producing camera frame in `NavigationCameraState.following` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.center` property.
     
     Defaults to `true`.
     */
    public var centerUpdatesAllowed = true
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.zoom` property
     when producing camera frame in `NavigationCameraState.following` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.zoom` property.
     
     Defaults to `true`.
     */
    public var zoomUpdatesAllowed = true
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.bearing` property
     when producing camera frame in `NavigationCameraState.following` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.bearing` property.
     
     Defaults to `true`.
     */
    public var bearingUpdatesAllowed = true
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.pitch` property
     when producing camera frame in `NavigationCameraState.following` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.pitch` property.
     
     Defaults to `true`.
     */
    public var pitchUpdatesAllowed = true
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.padding` property
     when producing camera frame in `NavigationCameraState.following` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.padding` property.
     
     Defaults to `true`.
     */
    public var paddingUpdatesAllowed = true
    
    /**
     Options, which allow to modify `CameraOptions.bearing` property based on information about
     bearing of an upcoming maneuver.
     */
    public var bearingSmoothing: BearingSmoothing = BearingSmoothing()
    
    /**
     Options, which allow to modify framed route geometries by appending additional coordinates after
     maneuver to extend the view.
     */
    public var frameGeometryAfterManeuver: FrameGeometryAfterManeuver = FrameGeometryAfterManeuver()
}

/**
 Options, which allow to modify `CameraOptions.bearing` property based on information about
 bearing of an upcoming maneuver.
 */
public struct BearingSmoothing {
    
    /**
     Controls how much the bearing can deviate from the location's bearing, in degrees.
     
     In case if set, the `bearing` property of `CameraOptions` during active guidance navigation
     won't exactly reflect the bearing returned by the location, but will also be affected by the
     direction to the upcoming framed geometry, to maximize the viewable area.
     
     Defaults to `45.0` degrees.
     */
    public var maximumBearingSmoothingAngle: CLLocationDirection? = 45.0
}

/**
 Options, which allow to modify framed route geometries by appending additional coordinates after
 maneuver to extend the view.
 */
public struct FrameGeometryAfterManeuver {
    
    /**
     Controls whether additional coordinates after the upcoming maneuver will be framed
     to provide the view extension.
     
     Defaults to `true`.
     */
    public var enabled: Bool = true
    
    /**
     Controls the distance between maneuvers closely following the current one to include them
     in the frame.
     
     Defaults to `150.0` meters.
     */
    public var distanceToCoalesceCompoundManeuvers: CLLocationDistance = 150.0
    
    /**
     Controls the distance on the route after the current maneuver to include it in the frame.
     
     Defaults to `100.0` meters.
     */
    public var distanceToFrameAfterManeuver: CLLocationDistance = 100.0
}
