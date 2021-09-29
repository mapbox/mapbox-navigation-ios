import CoreLocation

/**
 Options, which are used to control what `CameraOptions` parameters will be modified by
 `NavigationViewportDataSource` in `NavigationCameraState.following` state.
 */
public struct FollowingCameraOptions: Equatable {

    // MARK: Restricting the Orientation
    
    /**
     Pitch, which will be taken into account when preparing `CameraOptions` during active guidance
     navigation.
     
     Defaults to `45.0` degrees.

     - Invariant: Acceptable range of values is `0...85`.
     */
    public var defaultPitch: Double = 45.0 {
        didSet {
            if defaultPitch < 0.0 {
                defaultPitch = 0
                assertionFailure("Lower bound of the pitch should not be lower than 0.0")
            }
            
            if defaultPitch > 85.0 {
                defaultPitch = 85
                assertionFailure("Upper bound of the pitch should not be higher than 85.0")
            }
        }
    }
    
    /**
     Zoom levels range, which will be used when producing camera frame in `NavigationCameraState.following`
     state.
     
     Upper bound of the range will be also used as initial zoom level when active guidance navigation starts.
     
     Lower bound defaults to `10.50`, upper bound defaults to `16.35`.

     - Invariant: Acceptable range of values is `0...22`.
     */
    public var zoomRange: ClosedRange<Double> = 10.50...16.35 {
        didSet {
            let newValue = zoomRange

            if newValue.lowerBound < 0.0 || newValue.upperBound > 22.0 {
                zoomRange = max(0, zoomRange.lowerBound)...min(22, zoomRange.upperBound)
            }
            
            if newValue.lowerBound < 0.0 {
                assertionFailure("Lower bound of the zoom range should not be lower than 0.0")
            }

            if newValue.upperBound > 22.0 {
                assertionFailure("Upper bound of the zoom range should not be higher than 22.0")
            }
        }
    }
    
    // MARK: Camera Frame Modification Flags
    
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
    public var zoomUpdatesAllowed: Bool = true
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.bearing` property
     when producing camera frame in `NavigationCameraState.following` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.bearing` property.
     
     Defaults to `true`.
     */
    public var bearingUpdatesAllowed: Bool = true
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.pitch` property
     when producing camera frame in `NavigationCameraState.following` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.pitch` property.
     
     Defaults to `true`.
     */
    public var pitchUpdatesAllowed: Bool = true
    
    /**
     If `true`, `NavigationViewportDataSource` will continuously modify `CameraOptions.padding` property
     when producing camera frame in `NavigationCameraState.following` state.
     
     If `false`, `NavigationViewportDataSource` will not modify `CameraOptions.padding` property.
     
     Defaults to `true`.
     */
    public var paddingUpdatesAllowed: Bool = true
    
    // MARK: Emphasizing the Upcoming Maneuver
    
    /**
     Options, which allow to modify the framed route geometries based on the intersection density.
     
     By default the whole remainder of the step is framed, while `IntersectionDensity` options shrink
     that geometry to increase the zoom level.
     */
    public var intersectionDensity: IntersectionDensity = IntersectionDensity()
    
    /**
     Options, which allow to modify `CameraOptions.bearing` property based on information about
     bearing of an upcoming maneuver.
     */
    public var bearingSmoothing: BearingSmoothing = BearingSmoothing()
    
    /**
     Options, which allow to modify framed route geometries by appending additional coordinates after
     maneuver to extend the view.
     */
    public var geometryFramingAfterManeuver: GeometryFramingAfterManeuver = GeometryFramingAfterManeuver()
    
    /**
     Options, which allow to modify the framed route geometries when approaching a maneuver.
     */
    public var pitchNearManeuver: PitchNearManeuver = PitchNearManeuver()
    
    /**
     Initializes `FollowingCameraOptions` instance.
     */
    public init() {
        // No-op
    }
    
    public static func == (lhs: FollowingCameraOptions, rhs: FollowingCameraOptions) -> Bool {
        return lhs.defaultPitch == rhs.defaultPitch &&
            lhs.zoomRange == rhs.zoomRange &&
            lhs.centerUpdatesAllowed == rhs.centerUpdatesAllowed &&
            lhs.zoomUpdatesAllowed == rhs.zoomUpdatesAllowed &&
            lhs.bearingUpdatesAllowed == rhs.bearingUpdatesAllowed &&
            lhs.pitchUpdatesAllowed == rhs.pitchUpdatesAllowed &&
            lhs.paddingUpdatesAllowed == rhs.paddingUpdatesAllowed &&
            lhs.intersectionDensity == rhs.intersectionDensity &&
            lhs.bearingSmoothing == rhs.bearingSmoothing &&
            lhs.geometryFramingAfterManeuver == rhs.geometryFramingAfterManeuver &&
            lhs.pitchNearManeuver == rhs.pitchNearManeuver
    }
}

/**
 Options, which allow to modify the framed route geometries based on the intersection density.
 
 By default the whole remainder of the step is framed, while `IntersectionDensity` options shrink
 that geometry to increase the zoom level.
 */
public struct IntersectionDensity: Equatable {
    
    /**
     Controls whether additional coordinates after the upcoming maneuver will be framed
     to provide the view extension.
     
     Defaults to `true`.
     */
    public var enabled: Bool = true
    
    /**
     Multiplier, which will be used to adjust the size of the portion of the remaining step that's
     going to be selected for framing.
     
     Defaults to `7.0`.
     */
    public var averageDistanceMultiplier: Double = 7.0
    
    /**
     Minimum distance between intersections to count them as two instances.
     
     This has an effect of filtering out intersections based on parking lot entrances,
     driveways and alleys from the average intersection distance.
     
     Defaults to `20.0` meters.
     */
    public var minimumDistanceBetweenIntersections: CLLocationDistance = 20.0
    
    /**
     Initializes `IntersectionDensity` instance.
     */
    public init() {
        // No-op
    }
    
    public static func == (lhs: IntersectionDensity, rhs: IntersectionDensity) -> Bool {
        return lhs.enabled == rhs.enabled &&
            lhs.averageDistanceMultiplier == rhs.averageDistanceMultiplier &&
            lhs.minimumDistanceBetweenIntersections == rhs.minimumDistanceBetweenIntersections
    }
}

/**
 Options, which allow to modify `CameraOptions.bearing` property based on information about
 bearing of an upcoming maneuver.
 */
public struct BearingSmoothing: Equatable {
    
    /**
     Controls whether bearing smoothing will be performed or not.
     
     Defaults to `true`.
     */
    public var enabled: Bool = true
    
    /**
     Controls how much the bearing can deviate from the location's bearing, in degrees.
     
     In case if set, the `bearing` property of `CameraOptions` during active guidance navigation
     won't exactly reflect the bearing returned by the location, but will also be affected by the
     direction to the upcoming framed geometry, to maximize the viewable area.
     
     Defaults to `45.0` degrees.
     */
    public var maximumBearingSmoothingAngle: CLLocationDirection = 45.0
    
    /**
     Initializes `BearingSmoothing` instance.
     */
    public init() {
        // No-op
    }
    
    public static func == (lhs: BearingSmoothing, rhs: BearingSmoothing) -> Bool {
        return lhs.enabled == rhs.enabled &&
            lhs.maximumBearingSmoothingAngle == rhs.maximumBearingSmoothingAngle
    }
}

/**
 Options, which allow to modify framed route geometries by appending additional coordinates after
 maneuver to extend the view.
 */
public struct GeometryFramingAfterManeuver: Equatable {
    
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
    
    /**
     Initializes `GeometryFramingAfterManeuver` instance.
     */
    public init() {
        // No-op
    }
    
    public static func == (lhs: GeometryFramingAfterManeuver, rhs: GeometryFramingAfterManeuver) -> Bool {
        return lhs.enabled == rhs.enabled &&
            lhs.distanceToCoalesceCompoundManeuvers == rhs.distanceToCoalesceCompoundManeuvers &&
            lhs.distanceToFrameAfterManeuver == rhs.distanceToFrameAfterManeuver
    }
}

/**
 Options, which allow to modify the framed route geometries when approaching a maneuver.
 */
public struct PitchNearManeuver: Equatable {
    
    /**
     Controls whether `CameraOptions.pitch` will be set to `0.0` near upcoming maneuver.
     
     Defaults to `true`.
     */
    public var enabled: Bool = true
    
    /**
     Threshold distance to the upcoming maneuver.
     
     Defaults to `180.0` meters.
     */
    public var triggerDistanceToManeuver: CLLocationDistance = 180.0
    
    /**
     Initializes `PitchNearManeuver` instance.
     */
    public init() {
        // No-op
    }
    
    public static func == (lhs: PitchNearManeuver, rhs: PitchNearManeuver) -> Bool {
        return lhs.enabled == rhs.enabled &&
            lhs.triggerDistanceToManeuver == rhs.triggerDistanceToManeuver
    }
}
