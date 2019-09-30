import Foundation
import CoreLocation
import MapboxDirections


// MARK: - RouteController
/**
 Maximum number of meters the user can travel away from step before `RouteControllerShouldReroute` is emitted.
 */
public var RouteControllerMaximumDistanceBeforeRecalculating: CLLocationDistance = 50

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
 :nodoc This is used internally for debugging metrics
 */
public var NavigationMetricsDebugLoggingEnabled = "MBNavigationMetricsDebugLoggingEnabled"

/**
 For shorter upcoming steps, we link the `AlertLevel.high` instruction. If the upcoming step duration is near the duration of `RouteControllerHighAlertInterval`, we need to apply a bit of a buffer to prevent back to back notifications.
 
 A multiplier of `1.2` gives us a buffer of 3 seconds, enough time insert a new instruction.
 */
public let RouteControllerLinkedInstructionBufferMultiplier: Double = 1.2

/**
 The minimum speed value before the user's actual location can be considered over the snapped location.
 */
public var RouteSnappingMinimumSpeed: CLLocationSpeed = 3

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
 Minimum duration remaining in seconds for proactive rerouting to be active.
 */
public var RouteControllerMinimumDurationRemainingForProactiveRerouting: TimeInterval = 600

/**
 The number of seconds between attempts to automatically calculate a more optimal route while traveling.
 */
public var RouteControllerProactiveReroutingInterval: TimeInterval = 120

let FasterRouteFoundEvent = "navigation.fasterRoute"

//MARK: - Route Snapping (CLLocation)
/**
 Accepted deviation excluding horizontal accuracy before the user is considered to be off route.
 */
public var RouteControllerUserLocationSnappingDistance: CLLocationDistance = 15

/**
 Maximum angle the user puck will be rotated when snapping the user's course to the route line.
 */
public var RouteSnappingMaxManipulatedCourseAngle: CLLocationDirection = 45

/**
 Minimum Accuracy (maximum deviation, in meters) that the route snapping engine will accept before it stops snapping.
 */
public var RouteSnappingMinimumHorizontalAccuracy: CLLocationAccuracy = 20.0

/**
 Minimum number of consecutive incorrect course updates before rerouting occurs.
 */
public var RouteControllerMinNumberOfInCorrectCourses: Int = 4

/**
 Given a location update, the `horizontalAccuracy` is used to figure out how many consective location updates to wait before rerouting due to consecutive incorrect course updates.
 */
public var RouteControllerIncorrectCourseMultiplier: Int = 4



/**
 When calculating the user's snapped location, this constant will be used for deciding upon which step coordinates to include in the calculation.
 */
public var RouteControllerMaximumSpeedForUsingCurrentStep: CLLocationSpeed = 1





public extension Notification.Name {
    /**
     Posted when `RouteController` receives a user location update representing movement along the expected route.
     
     The user info dictionary contains the keys `MBRouteControllerRouteProgressKey` and `MBRouteControllerLocationKey`.
     
     :nodoc:
     */
    static let routeControllerProgressDidChange: Notification.Name = "RouteControllerProgressDidChange"
    
    /**
     Posted after the user diverges from the expected route, just before `RouteController` attempts to calculate a new route.
     
     The user info dictionary contains the key `MBRouteControllerLocationKey`.
     
     :nodoc:
     */
    static let routeControllerWillReroute: Notification.Name = "RouteControllerWillReroute"
    
    /**
     Posted when `RouteController` obtains a new route in response to the user diverging from a previous route.
     
     The user info dictionary contains the keys `MBRouteControllerLocationKey` and `MBRouteControllerIsProactiveKey`.
     
     :nodoc:
     */
    static let routeControllerDidReroute: Notification.Name = "RouteControllerDidReroute"
    
    /**
     Posted when `RouteController` fails to reroute the user after the user diverges from the expected route.
     
     The user info dictionary contains the key `MBRouteControllerRoutingErrorKey`.
     
     :nodoc:
     */
    static let routeControllerDidFailToReroute: Notification.Name = "RouteControllerDidFailToReroute"
    
    /**
     Posted when `RouteController` detects that the user has passed an ideal point for saying an instruction aloud.
     
     The user info dictionary contains the key `MBRouteControllerRouteProgressKey`.
     
     :nodoc:
     */
    static let routeControllerDidPassSpokenInstructionPoint: Notification.Name =  "RouteControllerDidPassSpokenInstructionPoint"
    
    /**
     Posted when `RouteController` detects that the user has passed an ideal point for display an instruction visually.
     
     The user info dictionary contains the key `MBRouteControllerRouteProgressKey`.
     
     :nodoc:
     */
    static let routeControllerDidPassVisualInstructionPoint: Notification.Name = "MBRouteControllerDidPassVisualInstructionPoint"
    
    /**
    Posted when something changes in the shared `MBNavigationSettings` object.
    
    The user info dictionary indicates which keys and values changed.
    
    :nodoc:
    */
    static let navigationSettingsDidChangeNotification: Notification.Name = "MBNavigationSettingsDidChange"
}

/**
Keys in the user info dictionaries of various notifications posted by instances
of `RouteController`.
*/
public struct RouteControllerNotificationUserInfoKey: Hashable, Equatable, RawRepresentable, ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public typealias RawValue = String

    public var rawValue: String

    public init(rawValue: String) {
    self.rawValue = rawValue
}
    public init(stringLiteral value: Self.StringLiteralType) {
        self.init(rawValue: value)
    }
    
    public static let routeProgressKey: RouteControllerNotificationUserInfoKey = "progress"
    public static let locationKey: RouteControllerNotificationUserInfoKey = "location"
    public static let rawLocationKey: RouteControllerNotificationUserInfoKey = "rawLocation"
    public static let routingErrorKey: RouteControllerNotificationUserInfoKey = "error"
    public static let visualInstructionKey: RouteControllerNotificationUserInfoKey = "visualInstruction"
    public static let spokenInstructionKey: RouteControllerNotificationUserInfoKey = "spokenInstruction"
    public static let isProactiveKey: RouteControllerNotificationUserInfoKey = "RouteControllerDidFindFasterRoute"
    
}

/**
Constant representing the domain in which errors created in this library will live under.
*/
public let MBErrorDomain = "MBErrorDomain"

extension Notification.Name: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: Self.StringLiteralType) {
        self.init(rawValue: value)
    }
    
}
