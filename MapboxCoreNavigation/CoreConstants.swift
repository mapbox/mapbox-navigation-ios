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
 
 In addition to calculating a more optimal route, `RouteController` also refreshes time-dependent statistics about the route, such as traffic congestion and the remaining duration, as long as `DirectionsOptions.profileIdentifier` is set to `DirectionsProfileIdentifier.automobileAvoidingTraffic` and `RouteOptions.refreshingEnabled` is set to `true`.
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
     Posted when `PassiveLocationDataSource` receives a user location update representing movement along the expected route.
     
     The user info dictionary contains the keys `PassiveLocationDataSource.NotificationUserInfoKey.locationKey`, `PassiveLocationDataSource.NotificationUserInfoKey.rawLocationKey`, `PassiveLocationDataSource.NotificationUserInfoKey.matchesKey`, and `PassiveLocationDataSource.NotificationUserInfoKey.roadNameKey`.
     
     - seealso: `routeControllerProgressDidUpdate`
     */
    static let passiveLocationDataSourceDidUpdate: Notification.Name = .init(rawValue: "PassiveLocationDataSourceDidUpdate")
    
    /**
     Posted when `RouteController` receives a user location update representing movement along the expected route.
     
     The user info dictionary contains the keys `RouteController.NotificationUserInfoKey.routeProgressKey`, `RouteController.NotificationUserInfoKey.locationKey`, and `RouteController.NotificationUserInfoKey.rawLocationKey`.
     
     - seealso: `passiveLocationDataSourceDidUpdate`
     */
    static let routeControllerProgressDidChange: Notification.Name = .init(rawValue: "RouteControllerProgressDidChange")
    
    /**
     Posted when `RouteController` receives updated information about the current route.
     
     The user info dictionary contains the key `RouteController.NotificationUserInfoKey.routeProgressKey`.
     */
    static let routeControllerDidRefreshRoute: Notification.Name = .init(rawValue: "RouteControllerDidRefreshRoute")
    
    /**
     Posted after the user diverges from the expected route, just before `RouteController` attempts to calculate a new route.
     
     The user info dictionary contains the key `RouteController.NotificationUserInfoKey.locationKey`.
     */
    static let routeControllerWillReroute: Notification.Name = .init(rawValue: "RouteControllerWillReroute")
    
    /**
     Posted when `RouteController` obtains a new route in response to the user diverging from a previous route.
     
     The user info dictionary contains the keys `RouteController.NotificationUserInfoKey.locationKey` and `RouteController.NotificationUserInfoKey.isProactiveKey`.
     */
    static let routeControllerDidReroute: Notification.Name = .init(rawValue: "RouteControllerDidReroute")
    
    /**
     Posted when `RouteController` fails to reroute the user after the user diverges from the expected route.
     
     The user info dictionary contains the key `RouteController.NotificationUserInfoKey.routingErrorKey`.
     */
    static let routeControllerDidFailToReroute: Notification.Name = .init(rawValue: "RouteControllerDidFailToReroute")
    
    /**
     Posted when `RouteController` detects that the user has passed an ideal point for saying an instruction aloud.
     
     The user info dictionary contains the keys `RouteController.NotificationUserInfoKey.routeProgressKey` and `RouteController.NotificationUserInfoKey.spokenInstructionKey`.
     */
    static let routeControllerDidPassSpokenInstructionPoint: Notification.Name =  .init(rawValue: "RouteControllerDidPassSpokenInstructionPoint")
    
    /**
     Posted when `RouteController` detects that the user has passed an ideal point for display an instruction visually.
     
     The user info dictionary contains the keys `RouteController.NotificationUserInfoKey.routeProgressKey` and `RouteController.NotificationUserInfoKey.visualInstructionKey`.
     */
    static let routeControllerDidPassVisualInstructionPoint: Notification.Name = .init(rawValue: "RouteControllerDidPassVisualInstructionPoint")
    
    /**
     Posted when something changes in the shared `NavigationSettings` object.
     
     The user info dictionary indicates which keys and values changed.
     */
    static let navigationSettingsDidChange: Notification.Name = .init(rawValue: "NavigationSettingsDidChange")
    
    /**
     Posted when user changes location authorization settings.
     
     The user info dictionary contains the key `MapboxNavigationService.NotificationUserInfoKey.locationAuthorizationKey`.
    */
    static let locationAuthorizationDidChange: Notification.Name = .init(rawValue: "LocationAuthorizationDidChange")
 
}

extension RouteController {
    /**
     Keys in the user info dictionaries of various notifications posted by instances of `RouteController`.
     */
    public struct NotificationUserInfoKey: Hashable, Equatable, RawRepresentable {
        public typealias RawValue = String

        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        /**
         A key in the user info dictionary of a `Notification.Name.routeControllerProgressDidChange`, `Notification.Name.routeControllerDidPassVisualInstructionPoint`, or `Notification.Name.routeControllerDidPassSpokenInstructionPoint` notification. The corresponding value is a `RouteProgress` object representing the current route progress.
         */
        public static let routeProgressKey: NotificationUserInfoKey = .init(rawValue: "progress")
        
        /**
         A key in the user info dictionary of a `Notification.Name.routeControllerProgressDidChange`, `Notification.Name.routeControllerWillReroute`, or `Notification.Name.routeControllerDidReroute` notification. The corresponding value is a `CLLocation` object representing the current idealized user location.
         */
        public static let locationKey: NotificationUserInfoKey = .init(rawValue: "location")
        
        /**
         A key in the user info dictionary of a `Notification.Name.routeControllerProgressDidChange` notification. The corresponding value is a `CLLocation` object representing the current raw user location.
         */
        public static let rawLocationKey: NotificationUserInfoKey = .init(rawValue: "rawLocation")
        
        /**
         A key in the user info dictionary of a `Notification.Name.routeControllerDidFailToReroute` notification. The corresponding value is an `NSError` object indicating why `RouteController` was unable to calculate a new route.
         */
        public static let routingErrorKey: NotificationUserInfoKey = .init(rawValue: "error")
        
        /**
         A key in the user info dictionary of an `Notification.Name.routeControllerDidPassVisualInstructionPoint`. The corresponding value is an `VisualInstruction` object representing the current visual instruction.
         */
        public static let visualInstructionKey: NotificationUserInfoKey = .init(rawValue: "visualInstruction")
        
        /**
         A key in the user info dictionary of a `Notification.Name.routeControllerDidPassSpokenInstructionPoint` notification. The corresponding value is an `SpokenInstruction` object representing the current visual instruction.
         */
        public static let spokenInstructionKey: NotificationUserInfoKey = .init(rawValue: "spokenInstruction")
        
        /**
         A key in the user info dictionary of a `Notification.Name.routeControllerDidReroute` notification. The corresponding value is an `NSNumber` instance containing a Boolean value indicating whether `RouteController` proactively rerouted the user onto a faster route.
         */
        public static let isProactiveKey: NotificationUserInfoKey = .init(rawValue: "RouteControllerDidFindFasterRoute")
    }
}

extension PassiveLocationDataSource {
    /**
     Keys in the user info dictionaries of various notifications posted by instances of `PassiveLocationDataSource`.
     */
    public struct NotificationUserInfoKey: Hashable, Equatable, RawRepresentable {
        public typealias RawValue = String

        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        /**
         A key in the user info dictionary of a `Notification.Name.passiveLocationDataSourceDidUpdate` notification. The corresponding value is a `CLLocation` object representing the current idealized user location.
         */
        public static let locationKey: NotificationUserInfoKey = .init(rawValue: "location")
        
        /**
         A key in the user info dictionary of a `Notification.Name.passiveLocationDataSourceDidUpdate` notification. The corresponding value is a `CLLocation` object representing the current raw user location.
         */
        public static let rawLocationKey: NotificationUserInfoKey = .init(rawValue: "rawLocation")
        
        /**
         A key in the user info dictionary of a `Notification.Name.passiveLocationDataSourceDidUpdate` notification. The corresponding value is an array of `Match` objects representing possible matches against the road network.
         */
        public static let matchesKey: NotificationUserInfoKey = .init(rawValue: "matches")
        
        /**
         A key in the user info dictionary of a `Notification.Name.passiveLocationDataSourceDidUpdate` notification. The corresponding value is a string representing the name of the road the user is currently traveling on.
         
         - seealso: `WayNameView`
         */
        public static let roadNameKey: NotificationUserInfoKey = .init(rawValue: "roadName")
    }
}

extension MapboxNavigationService {
    /**
     Keys in the user info dictionaries of various notifications posted by instances of `NavigationService`.
     */
    public struct NotificationUserInfoKey: Hashable, Equatable, RawRepresentable {
        public typealias RawValue = String
        public var rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        /**
         A key in the user info dictionary of a `Notification.Name.locationAuthorizationDidChange` notification. The corresponding value is a CLAccuracyAuthorization` indicating the current location authorization setting. */
        public static let locationAuthorizationKey: NotificationUserInfoKey = .init(rawValue: "locationAuthorization")
    }
}
