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
 Key used for accessing the `RouteProgress` object from a `RouteControllerAlertLevelDidChange` notification's `userInfo` dictionary.
 */
public let RouteControllerAlertLevelDidChangeNotificationRouteProgressKey = MBRouteControllerAlertLevelDidChangeNotificationRouteProgressKey

/**
 Key used for accessing the user's snapped distance to the end of the maneuver (CLLocationDistance) from a `RouteControllerAlertLevelDidChange` notification's `userInfo` dictionary.
 */
public let RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey = MBRouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey

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
 Emitted when the user moves along the route.
 */
public let RouteControllerProgressDidChange = Notification.Name(MBRouteControllerNotificationProgressDidChange)

/**
 Emitted when the alert level changes. This indicates the user should be notified about the upcoming maneuver.
 */
public let RouteControllerAlertLevelDidChange = Notification.Name(MBRouteControllerAlertLevelDidChange)

/**
 Emitted when the user has gone off-route and the `RouteController` is about to reroute.
 */
public let RouteControllerWillReroute = Notification.Name(MBRouteControllerWillReroute)

/**
 Emitted after the user has gone off-route and the `RouteController` rerouted.
 */
public let RouteControllerDidReroute = Notification.Name(MBRouteControllerDidReroute)

/**
 Emitted after the user has gone off-route but the `RouteController` failed to reroute.
 */
public let RouteControllerDidFailToReroute = Notification.Name(MBRouteControllerDidFailToReroute)

/**
 Maximum number of meters the user can travel away from step before `RouteControllerShouldReroute` is emitted.
 */
public var RouteControllerMaximumDistanceBeforeRecalculating: CLLocationDistance = 50

/**
 Accepted deviation excluding horizontal accuracy before the user is considered to be off route.
 */
public var RouteControllerUserLocationSnappingDistance: CLLocationDistance = 10

/**
 Threshold user must be in within to count as completing a step. One of two heuristics used to know when a user completes a step, see `RouteControllerManeuverZoneRadius`.
 
 The users `heading` and the `finalHeading` are compared. If this number is within `RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion`, the user has completed the step.
 */
public var RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion: Double = 30


/**
 Number of seconds left on step when a `medium` alert is emitted.
 */
public var RouteControllerMediumAlertInterval: TimeInterval = 70


/**
 Number of seconds left on step when a `high` alert is emitted.
 */
public var RouteControllerHighAlertInterval: TimeInterval = 15


/**
 Radius in meters the user must enter to count as completing a step. One of two heuristics used to know when a user completes a step, see `RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion`.
 */
public var RouteControllerManeuverZoneRadius: CLLocationDistance = 40


/**
 Maximum number of seconds the user can travel away from the start of the route before rerouting occurs
 */
public var MaxSecondsSpentTravelingAwayFromStartOfRoute: TimeInterval = 3


/**
 Remaing distance on a motorway at which the `.high` `AlertLevel` will be given. This overrides `RouteControllerHighAlertInterval` only when the current step is a motorway. Default value is a half mile.
 */
public var RouteControllerMotorwayHighAlertDistance: CLLocationDistance = 804.672


/**
 Remaing distance on a motorway at which the `.medium` `AlertLevel` will be given. This overrides `RouteControllerMediumAlertInterval` only when the current step is a motorway. Defauly value is 2 miles.
 */
public var RouteControllerMotorwayMediumAlertDistance: CLLocationDistance = 3218.69


/**
 When calculating whether or not the user is on the route, we look where the user will be given their speed and this variable.
 */
public var RouteControllerDeadReckoningTimeInterval:TimeInterval = 1.0


/**
 Maximum angle the user puck will be rotated when snapping the user's course to the route line.
 */
public var RouteControllerMaxManipulatedCourseAngle:CLLocationDirection = 25

/**
 :nodoc This is used internally for debugging metrics
 */
public var NavigationMetricsDebugLoggingEnabled = "MBNavigationMetricsDebugLoggingEnabled"
