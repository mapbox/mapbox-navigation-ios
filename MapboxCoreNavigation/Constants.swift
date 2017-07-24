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
 Distance in meters for the minimum length of a step for giving a `medium` alert while using `MBDirectionsProfileIdentifierAutomobile` or `MBDirectionsProfileIdentifierAutomobileAvoidingTraffic`.
 */
public var RouteControllerMinimumDistanceForMediumAlertDriving: CLLocationDistance = 400


/**
 Distance in meters for the minimum length of a step for giving a `medium` alert while using `MBDirectionsProfileIdentifierCycling`.
 */
public var RouteControllerMinimumDistanceForMediumAlertCycling: CLLocationDistance = 200


/**
 Distance in meters for the minimum length of a step for giving a `medium` alert while using `MBDirectionsProfileIdentifierWalking`.
 */
public var RouteControllerMinimumDistanceForMediumAlertWalking: CLLocationDistance = 100


/**
 Returns the appropriate `mediium` `AlertLevel` distance for a given `MBDirectionsProfileIdentifier`.
 */
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
 Distance in meters for the minimum length of a step for giving a `high` alert while using `MBDirectionsProfileIdentifierAutomobile` or `MBDirectionsProfileIdentifierAutomobileAvoidingTraffic`.
 */
public var RouteControllerMinimumDistanceForHighAlertDriving: CLLocationDistance = 100


/**
 Distance in meters for the minimum length of a step for giving a `high` alert while using `MBDirectionsProfileIdentifierCycling`.
 */
public var RouteControllerMinimumDistanceForHighAlertCycling: CLLocationDistance = 60


/**
 Distance in meters for the minimum length of a step for giving a `high` alert while using `MBDirectionsProfileIdentifierWalking`.
 */
public var RouteControllerMinimumDistanceForHighAlertWalking: CLLocationDistance = 20


/**
 Returns a the appropriate `high` `AlertLevel` distance for a given `MBDirectionsProfileIdentifier`.
 */
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

/**
 :nodoc This is used internally for debugging metrics
 */
public var NavigationMetricsDebugLoggingEnabled = "MBNavigationMetricsDebugLoggingEnabled"
