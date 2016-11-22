import Foundation
import CoreLocation

public let RouteControllerProgressDidChangeNotificationProgressKey = "progress"
public let RouteControllerProgressDidChangeNotificationLocationKey = "location"
public let RouteControllerProgressDidChangeNotificationSecondsRemainingOnStepKey = "seconds"
public let RouteControllerProgressDidChangeNotificationIsFirstAlertForStepKey = "first"

public let RouteControllerNotificationApproachingIncident = "incident"
public let RouteControllerAlertLevelDidChangeNotificationRouteProgressKey = "progress"
public let RouteControllerAlertLevelDidChangeNotificationDistanceToEndOfManeuverKey = "distance"
public let RouteControllerAlertLevelDidChangeNotificationDistanceToIncidentKey = "distance"

public let RouteControllerMaximumMetersBeforeRecalculating: CLLocationDistance = 50
public let RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion: Double = 30

public let RouteControllerMediumAlertInterval: TimeInterval = 70
public let RouteControllerHighAlertInterval: TimeInterval = 15
public let RouteControllerManeuverZoneRadius: CLLocationDistance = 40

public let RouteControllerMinimumDistanceForMediumAlert: CLLocationDistance = 400
public let RouteControllerMinimumDistanceForHighAlert: CLLocationDistance = 100

public let RouteControllerDeadReckoningTimeInterval:TimeInterval = 1.0

public let RouteControllerProgressDidChange = Notification.Name("RouteControllerProgressDidChange")
public let RouteControllerAlertLevelDidChange = Notification.Name("RouteControllerAlertLevelDidChange")
public let RouteControllerShouldReroute = Notification.Name("RouteControllerShouldReroute")
