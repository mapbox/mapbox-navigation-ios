import Foundation
import CoreLocation

public let RouteControllerProgressDidChangeNotificationProgressKey = MBRouteControllerProgressDidChangeNotificationProgressKey
public let RouteControllerProgressDidChangeNotificationLocationKey = MBRouteControllerProgressDidChangeNotificationLocationKey
public let RouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey = MBRouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey
public let RouteControllerProgressDidChangeNotificationIsFirstAlertForStepKey = MBRouteControllerProgressDidChangeNotificationIsFirstAlertForStepKey

public let RouteControllerAlertLevelDidChangeNotificationRouteProgressKey = MBRouteControllerAlertLevelDidChangeNotificationRouteProgressKey
public let RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey = MBRouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey

public let RouteControllerNotificationShouldRerouteKey = MBRouteControllerNotificationShouldRerouteKey

public let RouteControllerProgressDidChange = Notification.Name(MBRouteControllerNotificationProgressDidChange)
public let RouteControllerAlertLevelDidChange = Notification.Name(MBRouteControllerAlertLevelDidChange)
public let RouteControllerShouldReroute = Notification.Name(MBRouteControllerShouldReroute)

/*
 Maximum number of meters the user can travel away from step before `RouteControllerShouldReroute` is emitted.
*/
public var RouteControllerMaximumDistanceBeforeRecalculating: CLLocationDistance = 50


/*
 Threshold user must be in within to count as completing a step. One of two heuristics used to know when a user completes a step, see `RouteControllerManeuverZoneRadius`.
 
 The users `heading` and the `finalHeading` are compared. If this number is within `RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion`, the user has completed the step.
*/
public var RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion: Double = 30


/*
 Number of seconds left on step when a `medium` alert is emitted.
*/
public var RouteControllerMediumAlertInterval: TimeInterval = 70


/*
 Number of seconds left on step when a `high` alert is emitted.
 */
public var RouteControllerHighAlertInterval: TimeInterval = 15


/*
 Radius in meters the user must enter to count as completing a step. One of two heuristics used to know when a user completes a step, see `RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion`.
*/
public var RouteControllerManeuverZoneRadius: CLLocationDistance = 40


/*
 Distance in meters for the minimum length of a step for giving a `medium` alert.
*/
public var RouteControllerMinimumDistanceForMediumAlert: CLLocationDistance = 400


/*
 Distance in meters for the minimum length of a step for giving a `high` alert.
 */
public var RouteControllerMinimumDistanceForHighAlert: CLLocationDistance = 100


/*
 When calculating whether or not the user is on the route, we look where the user will be given their speed and this variable.
*/
public var RouteControllerDeadReckoningTimeInterval:TimeInterval = 1.0
