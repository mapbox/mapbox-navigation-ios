import Foundation
import CoreLocation
import MapboxDirections

public let RouteControllerProgressDidChangeNotificationProgressKey = MBRouteControllerProgressDidChangeNotificationProgressKey
public let RouteControllerProgressDidChangeNotificationLocationKey = MBRouteControllerProgressDidChangeNotificationLocationKey
public let RouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey = MBRouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey

public let RouteControllerAlertLevelDidChangeNotificationRouteProgressKey = MBRouteControllerAlertLevelDidChangeNotificationRouteProgressKey
public let RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey = MBRouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey

public let RouteControllerNotificationLocationKey = MBRouteControllerNotificationLocationKey
public let RouteControllerNotificationRouteKey = MBRouteControllerNotificationRouteKey
public let RouteControllerNotificationErrorKey = MBRouteControllerNotificationErrorKey

public let RouteControllerProgressDidChange = Notification.Name(MBRouteControllerNotificationProgressDidChange)
public let RouteControllerAlertLevelDidChange = Notification.Name(MBRouteControllerAlertLevelDidChange)
public let RouteControllerWillReroute = Notification.Name(MBRouteControllerWillReroute)
public let RouteControllerDidReroute = Notification.Name(MBRouteControllerDidReroute)
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
 Distance in meters for the minimum length of a step for giving a `medium` alert.
 */
public var RouteControllerMinimumDistanceForMediumAlertDriving: CLLocationDistance = 400
public var RouteControllerMinimumDistanceForMediumAlertCycling: CLLocationDistance = 200
public var RouteControllerMinimumDistanceForMediumAlertWalking: CLLocationDistance = 100

public func RouteControllerMinimumDistanceForMediumAlert(identifier: MBDirectionsProfileIdentifier) -> CLLocationDistance {
    switch identifier {
    case MBDirectionsProfileIdentifier.automobileAvoidingTraffic:
        return RouteControllerMinimumDistanceForMediumAlertDriving
    case MBDirectionsProfileIdentifier.automobile:
        return RouteControllerMinimumDistanceForMediumAlertDriving
    case MBDirectionsProfileIdentifier.cycling:
        return RouteControllerMinimumDistanceForMediumAlertCycling
    case MBDirectionsProfileIdentifier.walking:
        return RouteControllerMinimumDistanceForMediumAlertWalking
    default:
        break
    }
    
    return RouteControllerMinimumDistanceForMediumAlertDriving
}


/**
 Distance in meters for the minimum length of a step for giving a `high` alert.
 */
public var RouteControllerMinimumDistanceForHighAlertDriving: CLLocationDistance = 100
public var RouteControllerMinimumDistanceForHighAlertCycling: CLLocationDistance = 60
public var RouteControllerMinimumDistanceForHighAlertWalking: CLLocationDistance = 20

public func RouteControllerMinimumDistanceForHighAlert(identifier: MBDirectionsProfileIdentifier) -> CLLocationDistance {
    switch identifier {
    case MBDirectionsProfileIdentifier.automobileAvoidingTraffic:
        return RouteControllerMinimumDistanceForHighAlertDriving
    case MBDirectionsProfileIdentifier.automobile:
        return RouteControllerMinimumDistanceForHighAlertDriving
    case MBDirectionsProfileIdentifier.cycling:
        return RouteControllerMinimumDistanceForHighAlertCycling
    case MBDirectionsProfileIdentifier.walking:
        return RouteControllerMinimumDistanceForHighAlertWalking
    default:
        break
    }
    
    return RouteControllerMinimumDistanceForHighAlertDriving
}


/**
 When calculating whether or not the user is on the route, we look where the user will be given their speed and this variable.
 */
public var RouteControllerDeadReckoningTimeInterval:TimeInterval = 1.0


/**
 Maximum angle the user puck will be rotated when snapping the user's course to the route line.
 */
public var RouteControllerMaxManipulatedCourseAngle:CLLocationDirection = 25
