import Foundation
import CoreLocation
import MapboxDirections

/**
 Key used for accessing the `RouteProgress` object from a `RouteControllerProgressDidChange` notification's `userInfo` dictionary.
 */
public let RouteControllerProgressDidChangeNotificationProgressKey = MBRouteControllerProgressDidChangeNotificationProgressKey

/**
 Key used for accessing the `CLLocation` object from a `RouteControllerProgressDidChange` notification's `userInfo` dictionary.
 */
public let RouteControllerProgressDidChangeNotificationLocationKey = MBRouteControllerProgressDidChangeNotificationLocationKey

/**
 Key used for accessing the number of seconds left on a step (Double) from a `RouteControllerProgressDidChange` notification's `userInfo` dictionary.
 */
public let RouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey = MBRouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey

/**
 Key used for accessing the user's current `CLLocation` from a `RouteControllerWillReroute` notification's `userInfo` dictionary.
 */
public let RouteControllerNotificationLocationKey = MBRouteControllerNotificationLocationKey

/**
 Key used for accessing the newly rerouted `Route` from a `RouteControllerDidReroute` notification's `userInfo` dictionary.
 */
public let RouteControllerNotificationRouteKey = MBRouteControllerNotificationRouteKey

/**
 Key used for accessing the error from a `RouteControllerDidFailToReroute` notification's `userInfo` dictionary.
 */
public let RouteControllerNotificationErrorKey = MBRouteControllerNotificationErrorKey

/**
 Key used for accessing a `Bool` as to whether the reroute occurced because a faster route was found.
 */
public let RouteControllerDidFindFasterRouteKey = MBRouteControllerDidFindFasterRouteKey

/**
 Key for accessing the `RouteProgress` key emitted when `RouteControllerDidPassSpokenInstructionPoint` is fired.
 */
public let RouteControllerDidPassSpokenInstructionPointRouteProgressKey = MBRouteControllerDidPassSpokenInstructionPointRouteProgressKey

extension Notification.Name {
    /**
     Emitted after the user has gone off-route but the `RouteController` failed to reroute.
     */
    public static let routeControllerDidFailToReroute = Notification.Name(MBRouteControllerDidFailToReroute)
    /**
     Emitted when the user has gone off-route and the `RouteController` is about to reroute.
     */
    public static let routeControllerWillReroute = Notification.Name(MBRouteControllerWillReroute)
    
    /**
     Emitted after the user has gone off-route and the `RouteController` rerouted.
     */
    public static let routeControllerDidReroute = Notification.Name(MBRouteControllerDidReroute)
    
    /**
     Emitted when the user moves along the route.
     */
    public static let routeControllerProgressDidChange = Notification.Name(MBRouteControllerNotificationProgressDidChange)
    
    /**
     Emitted when the user passes an ideal point for saying an instruction aloud.
     */
    public static let routeControllerDidPassSpokenInstructionPoint = Notification.Name(MBRouteControllerDidPassSpokenInstructionPoint)
}

/**
 Maximum number of meters the user can travel away from step before `RouteControllerShouldReroute` is emitted.
 */
public var RouteControllerMaximumDistanceBeforeRecalculating: CLLocationDistance = 50

/**
 Accepted deviation excluding horizontal accuracy before the user is considered to be off route.
 */
public var RouteControllerUserLocationSnappingDistance: CLLocationDistance = 15

/**
 Threshold user must be in within to count as completing a step. One of two heuristics used to know when a user completes a step, see `RouteControllerManeuverZoneRadius`.
 
 The users `heading` and the `finalHeading` are compared. If this number is within `RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion`, the user has completed the step.
 */
public var RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion: Double = 30

/**
 Number of seconds left on step when a `AlertLevel.medium` alert is emitted.
 */
public var RouteControllerMediumAlertInterval: TimeInterval = 70

/**
 Number of seconds left on step when a `AlertLevel.high` alert is emitted.
 */
public var RouteControllerHighAlertInterval: TimeInterval = 15

/**
 Radius in meters the user must enter to count as completing a step. One of two heuristics used to know when a user completes a step, see `RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion`.
 */
public var RouteControllerManeuverZoneRadius: CLLocationDistance = 40

/**
 When calculating whether or not the user is on the route, we look where the user will be given their speed and this variable.
 */
public var RouteControllerDeadReckoningTimeInterval: TimeInterval = 1.0

/**
 Maximum angle the user puck will be rotated when snapping the user's course to the route line.
 */
public var RouteControllerMaxManipulatedCourseAngle: CLLocationDirection = 25

/**
 :nodoc This is used internally for debugging metrics
 */
public var NavigationMetricsDebugLoggingEnabled = "MBNavigationMetricsDebugLoggingEnabled"

/**
 For shorter upcoming steps, we link the `AlertLevel.high` instruction. If the upcoming step duration is near the duration of `RouteControllerHighAlertInterval`, we need to apply a bit of a buffer to prevent back to back notifications.
 
 A multiplier of `1.2` gives us a buffer of 3 seconds, enough time insert a new instruction.
 */
public let RouteControllerLinkedInstructionBufferMultiplier: Double = 1.2

/**
 Approximately the number of meters in a mile.
 */
let milesToMeters = 1609.34

/**
 The minimum speed value before the user's actual location can be considered over the snapped location.
 */
public var RouteControllerMinimumSpeedForLocationSnapping: CLLocationSpeed = 3

/**
 The minimum distance threshold used for giving a "Continue" type instructions.
 */
public var RouteControllerMinimumDistanceForContinueInstruction: CLLocationDistance = 2_000

/**
 The minimum distance in the opposite direction of travel that triggers rerouting.
 */
public var RouteControllerMinimumBacktrackingDistanceForRerouting: CLLocationDistance = 50

/**
 Minimum number of consecutive location updates moving backwards before the user is rerouted.
 */
public var RouteControllerMinimumNumberLocationUpdatesBackwards = 3

/**
 Number of seconds reroute feedback sections are shown in the feedback view after the user is rerouted.
 */
public var RouteControllerNumberOfSecondsForRerouteFeedback: TimeInterval = 10

/**
 The number of seconds between attempts to automatically calculate a more optimal route while traveling.
 */
public var RouteControllerOpportunisticReroutingInterval: TimeInterval = 120

let FasterRouteFoundEvent = "navigation.fasterRoute"

/**
 The number of seconds remaining on the final step of a leg before the user is considered "arrived".
 */
public var RouteControllerDurationRemainingWaypointArrival: TimeInterval = 3
