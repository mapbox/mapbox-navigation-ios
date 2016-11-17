import Foundation
import CoreLocation

public let NavigationControllerProgressDidChangeNotificationProgressKey = "progress"
public let NavigationControllerProgressDidChangeNotificationSecondsRemainingOnStepKey = "seconds"

public let NavigationControllerNotificationApproachingIncident = "incident"
public let NavigationControllerAlertLevelDidChangeNotificationRouteProgressKey = "progress"
public let NavigationControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey = "distance"
public let NavigationControllerAlertLevelDidChangeNotificationDistanceToIncidentKey = "distance"

public let NavigationControllerMaximumMetersBeforeRecalculating: CLLocationDistance = 50
public let NavigationControllerMaximumAllowedDegreeOffsetForTurnCompletion: Double = 30

// Alert distances
public let NavigationControllerMediumAlertNumberOfSeconds: Double = 70
public let NavigationControllerHighAlertNumberOfSeconds: Double = 15
public let NavigationControllerManeuverZoneRadius: CLLocationDistance = 40

public let NavigationControllerMinimumDistanceForMediumAlert: CLLocationDistance = 400
public let NavigationControllerMinimumDistanceForHighAlert: CLLocationDistance = 100

public let NavigationControllerDeadReckoningTimeInterval:TimeInterval = 1.0

public struct NavigationControllerNotification {
    static public let progressDidChange = Notification.Name("NavigationControllerProgressDidChange")
    static public let alertLevelDidChange = Notification.Name("NavigationControllerAlertLevelDidChange")
    static public let rerouted = Notification.Name("NavigationControllerShouldRerouted")
}
