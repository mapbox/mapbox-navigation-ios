import Foundation
import CoreLocation
import MapboxDirections

// MARK: RouteController Rerouting logic
/**
 Maximum number of meters the user can travel away from step before `RouteControllerShouldReroute` is emitted.
 */
public var RouteControllerMaximumDistanceBeforeRecalculating: CLLocationDistance = 50

/**
 When calculating whether or not the user is on the route, we look where the user will be given their speed and this variable.
 */
public var RouteControllerDeadReckoningTimeInterval: TimeInterval = 1.0

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

/**
 Minimum number of consecutive incorrect course updates before rerouting occurs.
 */
public var RouteControllerMinNumberOfInCorrectCourses: Int = 4

/**
 Given a location update, the `horizontalAccuracy` is used to figure out how many consective location updates to wait before rerouting due to consecutive incorrect course updates.
 */
public var RouteControllerIncorrectCourseMultiplier: Int = 4

let FasterRouteFoundEvent = "navigation.fasterRoute"

// MARK: Tracking RouteController Step Progress

/**
 Threshold user must be in within to count as completing a step. One of two heuristics used to know when a user completes a step, see `RouteControllerManeuverZoneRadius`.
 
 The users `heading` and the `finalHeading` are compared. If this number is within `RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion`, the user has completed the step.
 */
public var RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion: Double = 30

/**
 Radius in meters the user must enter to count as completing a step. One of two heuristics used to know when a user completes a step, see `RouteControllerMaximumAllowedDegreeOffsetForTurnCompletion`.
 */
public var RouteControllerManeuverZoneRadius: CLLocationDistance = 40

// MARK: RouteController Notifications Alerting

/**
 Number of seconds left on step when a `AlertLevel.medium` alert is emitted.
 */
public var RouteControllerMediumAlertInterval: TimeInterval = 70

/**
 Number of seconds left on step when a `AlertLevel.high` alert is emitted.
 */
public var RouteControllerHighAlertInterval: TimeInterval = 15

/**
 For shorter upcoming steps, we link the `AlertLevel.high` instruction. If the upcoming step duration is near the duration of `RouteControllerHighAlertInterval`, we need to apply a bit of a buffer to prevent back to back notifications.
 
 A multiplier of `1.2` gives us a buffer of 3 seconds, enough time insert a new instruction.
 */
public let RouteControllerLinkedInstructionBufferMultiplier: Double = 1.2

/**
 The minimum distance threshold used for giving a "Continue" type instructions.
 */
public var RouteControllerMinimumDistanceForContinueInstruction: CLLocationDistance = 2_000


// MARK: Configuring Route Snapping (CLLocation) for RouteController

/**
 The minimum speed value before the user's actual location can be considered over the snapped location.
 */
public var RouteSnappingMinimumSpeed: CLLocationSpeed = 3

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
 When calculating the user's snapped location, this constant will be used for deciding upon which step coordinates to include in the calculation.
 */
public var RouteControllerMaximumSpeedForUsingCurrentStep: CLLocationSpeed = 1

//MARK: - Congestion Level Default Ranges

/**
 Default range that matches `NumericCongestionLevel` values into `CongestionLevel.low` bucket.
 */
public let CongestionRangeLow: CongestionRange = 0..<40

/**
 Default range that matches `NumericCongestionLevel` values into `CongestionLevel.moderate` bucket.
 */
public let CongestionRangeModerate: CongestionRange = 40..<60

/**
 Default range that matches `NumericCongestionLevel` values into `CongestionLevel.heavy` bucket.
 */
public let CongestionRangeHeavy: CongestionRange = 60..<80

/**
 Default range that matches `NumericCongestionLevel` values into `CongestionLevel.severe` bucket.
 */
public let CongestionRangeSevere: CongestionRange = 80..<101

public extension Notification.Name {
    
    // MARK: PassiveLocationManager Events
    
    /**
     Posted when `PassiveLocationManager` receives a user location update representing movement along the expected route.
     
     The user info dictionary contains the keys `PassiveLocationManager.NotificationUserInfoKey.locationKey`, `PassiveLocationManager.NotificationUserInfoKey.rawLocationKey`, `PassiveLocationManager.NotificationUserInfoKey.matchesKey`,  `PassiveLocationManager.NotificationUserInfoKey.roadNameKey`, `PassiveLocationManager.NotificationUserInfoKey.mapMatchingResultKey` and `PassiveLocationManager.NotificationUserInfoKey.routeShieldRepresentationKey`.
     
     - seealso: `routeControllerProgressDidUpdate`
     */
    static let passiveLocationManagerDidUpdate: Notification.Name = .init(rawValue: "PassiveLocationManagerDidUpdate")
    
    // MARK: RouteController Events
    
    /**
     Posted when `RouteController` receives a user location update representing movement along the expected route.
     
     The user info dictionary contains the keys `RouteController.NotificationUserInfoKey.routeProgressKey`, `RouteController.NotificationUserInfoKey.locationKey`, `RouteController.NotificationUserInfoKey.rawLocationKey`, `RouteController.NotificationUserInfoKey.headingKey` and `RouteController.NotificationUserInfoKey.mapMatchingResultKey`.
     
     - note: Notification emitted by `LegacyRouteController` will not contain `RouteController.NotificationUserInfoKey.headingKey` and `RouteController.NotificationUserInfoKey.mapMatchingResultKey`.
     
     - seealso: `passiveLocationManagerDidUpdate`
     */
    static let routeControllerProgressDidChange: Notification.Name = .init(rawValue: "RouteControllerProgressDidChange")
    
    /**
     Posted when `RouteController` receives updated information about the current route.
     
     The user info dictionary contains the key `RouteController.NotificationUserInfoKey.routeProgressKey`.
     */
    static let routeControllerDidRefreshRoute: Notification.Name = .init(rawValue: "RouteControllerDidRefreshRoute")
    
    /**
     Posted after the user diverges from the expected route, just before `RouteController` attempts to calculate a new route.
     
     The user info dictionary contains the keys `RouteController.NotificationUserInfoKey.locationKey` and `RouteController.NotificationUserInfoKey.headingKey`.
     */
    static let routeControllerWillReroute: Notification.Name = .init(rawValue: "RouteControllerWillReroute")
    
    /**
     Posted when `RouteController` obtains a new route in response to the user diverging from a previous route.
     
     The user info dictionary contains the keys `RouteController.NotificationUserInfoKey.locationKey`, `RouteController.NotificationUserInfoKey.isProactiveKey`, and `RouteController.NotificationUserInfoKey.headingKey`.
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
     Posted when `RouteController` detects the road name.
     
     The user info dictionary contains the key `RouteController.NotificationUserInfoKey.roadNameKey` and `RouteController.NotificationUserInfoKey.routeShieldRepresentationKey`.
     */
    static let currentRoadNameDidChange: Notification.Name = .init(rawValue: "CurrentRoadNameDidChange")
    
    /**
     Posted when `RouteController` detects the arrival at waypoint.
     
     The user info dictionary contains the key `RouteController.NotificationUserInfoKey.waypointKey`.
     */
    static let didArriveAtWaypoint: Notification.Name = .init(rawValue: "DidArriveAtWaypoint")
    
    // MARK: Settings and Permissions Updates
    
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
    
    /**
     Posted when `NavigationService` update the simulating status.
     
     The user info dictionary contains the key `MapboxNavigationService.NotificationUserInfoKey.simulationStateKey` and `MapboxNavigationService.NotificationUserInfoKey.simulatedSpeedMultiplierKey`.
     */
    static let navigationServiceSimulationDidChange: Notification.Name = .init(rawValue: "NavigationServiceSimulationDidChange")
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
        
        // MARK: Route Traversal and Positioning Data
        
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
         A key in the user info dictionary of a `Notification.Name.routeControllerProgressDidChange` notification. The corresponding value is a `CLHeading` object representing the current user heading.
         */
        public static let headingKey: NotificationUserInfoKey = .init(rawValue: "heading")
        
        /**
         A key in the user info dictionary of a `Notification.Name.routeControllerProgressDidChange` notification. The corresponding value is a `MapMatchingResult` object representing the map matching state.
         */
        public static let mapMatchingResultKey: NotificationUserInfoKey = .init(rawValue: "mapMatchingResult")
        
        /**
         A key in the user info dictionary of a `Notification.Name.currentRoadNameDidChange` notification. The corresponding value is a `NSString` object representing the current road name.
         */
        public static let roadNameKey: NotificationUserInfoKey = .init(rawValue: "roadName")
        
        /**
         A key in the user info dictionary of a `Notification.Name.currentRoadNameDidChange` notification. The corresponding value is a `MapboxDirections.VisualInstruction.Component.ImageRepresentation` object representing the road shield the user is currently traveling on.
         */
        public static let routeShieldRepresentationKey: NotificationUserInfoKey = .init(rawValue: "routeShieldRepresentation")
        
        /**
         A key in the user info dictionary of a `Notification.Name.didArriveAtWaypoint` notification. The corresponding value is a `MapboxDirections.Waypoint` object representing the current destination waypoint.
         */
        public static let waypointKey: NotificationUserInfoKey = .init(rawValue: "waypoint")
        
        // MARK: Monitoring Rerouting
        
        /**
         A key in the user info dictionary of a `Notification.Name.routeControllerDidReroute` notification. The corresponding value is an `NSNumber` instance containing a Boolean value indicating whether `RouteController` proactively rerouted the user onto a faster route.
         */
        public static let isProactiveKey: NotificationUserInfoKey = .init(rawValue: "RouteControllerDidFindFasterRoute")
        
        /**
         A key in the user info dictionary of a `Notification.Name.routeControllerDidFailToReroute` notification. The corresponding value is an `NSError` object indicating why `RouteController` was unable to calculate a new route.
         */
        public static let routingErrorKey: NotificationUserInfoKey = .init(rawValue: "error")
        
        // MARK: Monitoring Instructions
        
        /**
         A key in the user info dictionary of an `Notification.Name.routeControllerDidPassVisualInstructionPoint`. The corresponding value is an `VisualInstruction` object representing the current visual instruction.
         */
        public static let visualInstructionKey: NotificationUserInfoKey = .init(rawValue: "visualInstruction")
        
        /**
         A key in the user info dictionary of a `Notification.Name.routeControllerDidPassSpokenInstructionPoint` notification. The corresponding value is an `SpokenInstruction` object representing the current visual instruction.
         */
        public static let spokenInstructionKey: NotificationUserInfoKey = .init(rawValue: "spokenInstruction")
    }
}

extension PassiveLocationManager {
    /**
     Keys in the user info dictionaries of various notifications posted by instances of `PassiveLocationManager`.
     */
    public struct NotificationUserInfoKey: Hashable, Equatable, RawRepresentable {
        public typealias RawValue = String

        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        // MARK: Positioning Data
        
        /**
         A key in the user info dictionary of a `Notification.Name.passiveLocationManagerDidUpdate` notification. The corresponding value is a `CLLocation` object representing the current idealized user location.
         */
        public static let locationKey: NotificationUserInfoKey = .init(rawValue: "location")
        
        /**
         A key in the user info dictionary of a `Notification.Name.passiveLocationManagerDidUpdate` notification. The corresponding value is a `CLLocation` object representing the current raw user location.
         */
        public static let rawLocationKey: NotificationUserInfoKey = .init(rawValue: "rawLocation")
        
        /**
         A key in the user info dictionary of a `Notification.Name.passiveLocationManagerDidUpdate` notification. The corresponding value is an array of `Match` objects representing possible matches against the road network.
         */
        public static let matchesKey: NotificationUserInfoKey = .init(rawValue: "matches")
        
        // MARK: Road Data
        
        /**
         A key in the user info dictionary of a `Notification.Name.passiveLocationManagerDidUpdate` notification. The corresponding value is a string representing the name of the road the user is currently traveling on.
         
         - seealso: `WayNameView`
         */
        public static let roadNameKey: NotificationUserInfoKey = .init(rawValue: "roadName")
        
        /**
         A key in the user info dictionary of a `Notification.Name.passiveLocationManagerDidUpdate` notification. The corresponding value is a `MapboxDirections.VisualInstruction.Component.ImageRepresentation` object representing the road shield the user is currently traveling on.
         */
        public static let routeShieldRepresentationKey: NotificationUserInfoKey = .init(rawValue: "routeShieldRepresentation")
        
        /**
         A key in the user info dictionary of a `Notification.Name.passiveLocationManagerDidUpdate` notification. The corresponding value is a `Measurement<UnitSpeed>` representing the maximum speed limit of the current road.
         */
        public static let speedLimitKey: NotificationUserInfoKey = .init(rawValue: "speedLimit")
        
        /**
         A key in the user info dictionary of a `Notification.Name.passiveLocationManagerDidUpdate` notification. The corresponding value is a `SignStandard` representing the sign standard used for speed limit signs along the current road.
         */
        public static let signStandardKey: NotificationUserInfoKey = .init(rawValue: "signStandard")
        
        /**
         A key in the user info dictionary of a `Notification.Name.passiveLocationManagerDidUpdate` notification. The corresponding value is a `MapMatchingResult` object representing the map matching state.
         */
        public static let mapMatchingResultKey: NotificationUserInfoKey = .init(rawValue: "mapMatchingResult")
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
         A key in the user info dictionary of a `Notification.Name.locationAuthorizationDidChange` notification. The corresponding value is a `CLAccuracyAuthorization` indicating the current location authorization setting. */
        public static let locationAuthorizationKey: NotificationUserInfoKey = .init(rawValue: "locationAuthorization")
        
        /**
         A key in the user info dictionary of a `Notification.Name.navigationServiceSimulationDidChange` notification. The corresponding value is a `SimulationState` indicating the current simulation status. */
        public static let simulationStateKey: NotificationUserInfoKey = .init(rawValue: "simulationState")
        
        /**
         A key in the user info dictionary of a `Notification.Name.navigationServiceSimulatingDidChange` notification. The corresponding value is a `Double` indicating the current simulated speed multiplier. */
        public static let simulatedSpeedMultiplierKey: NotificationUserInfoKey = .init(rawValue: "simulatedSpeedMultiplier")
    }
}

public extension Notification.Name {
    
    // MARK: Electronic Horizon Notifications
    
    /**
     Posted when the user’s position in the electronic horizon changes. This notification may be posted multiple times after `electronicHorizonDidEnterRoadObject` until the user transitions to a new electronic horizon.
     
     The user info dictionary contains the keys `RoadGraph.NotificationUserInfoKey.positionKey`, `RoadGraph.NotificationUserInfoKey.treeKey`, `RoadGraph.NotificationUserInfoKey.updatesMostProbablePathKey`, and `RoadGraph.NotificationUserInfoKey.distancesByRoadObjectKey`.
    */
    static let electronicHorizonDidUpdatePosition: Notification.Name = .init(rawValue: "ElectronicHorizonDidUpdatePosition")
    
    /**
     Posted when the user enters a linear road object.
     
     The user info dictionary contains the keys `RoadGraph.NotificationUserInfoKey.roadObjectIdentifierKey` and `RoadGraph.NotificationUserInfoKey.didTransitionAtEndpointKey`.
    */
    static let electronicHorizonDidEnterRoadObject: Notification.Name = .init(rawValue: "ElectronicHorizonDidEnterRoadObject")
    
    /**
     Posted when the user exits a linear road object.
     
     The user info dictionary contains the keys `RoadGraph.NotificationUserInfoKey.roadObjectIdentifierKey` and `RoadGraph.NotificationUserInfoKey.transitionKey`.
    */
    static let electronicHorizonDidExitRoadObject: Notification.Name = .init(rawValue: "ElectronicHorizonDidExitRoadObject")

    /**
     Posted when user has passed point-like object.

     The user info dictionary contains the key `ElectronicHorizon.NotificationUserInfoKey.roadObjectIdentifierKey`.
    */
    static let electronicHorizonDidPassRoadObject: Notification.Name = .init(rawValue: "ElectronicHorizonDidPassRoadObject")
}

extension RoadGraph {
    /**
     Keys in the user info dictionaries of various notifications posted by instances of `RouteController` or `PassiveLocationManager` about `RoadGraph`s.
     */
    public struct NotificationUserInfoKey: Hashable, Equatable, RawRepresentable {
        public typealias RawValue = String
        public var rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        /**
         A key in the user info dictionary of a `Notification.Name.electronicHorizonDidUpdatePosition` notification. The corresponding value is a `RoadGraph.Position` indicating the current position in the road graph. */
        public static let positionKey: NotificationUserInfoKey = .init(rawValue: "position")
        
        /**
         A key in the user info dictionary of a `Notification.Name.electronicHorizonDidUpdatePosition` notification. The corresponding value is an `RoadGraph.Edge` at the root of a tree of edges in the routing graph. This graph represents a probable path (or paths) of a vehicle within the routing graph for a certain distance in front of the vehicle, thus extending the user’s perspective beyond the “visible” horizon as the vehicle’s position and trajectory change.
         */
        public static let treeKey: NotificationUserInfoKey = .init(rawValue: "tree")
        
        /**
         A key in the user info dictionary of a `Notification.Name.electronicHorizonDidUpdatePosition` notification. The corresponding value is a Boolean value of `true` if the position update indicates a new most probable path (MPP) or `false` if it updates an existing MPP that the user has continued to follow.
         
         An electronic horizon can represent a new MPP in three scenarios:
         - An electronic horizon is detected for the very first time.
         - A user location tracking error leads to an MPP completely distinct from the previous MPP.
         - The user has departed from the previous MPP, for example by driving to a side path of the previous MPP.
         */
        public static let updatesMostProbablePathKey: NotificationUserInfoKey = .init(rawValue: "updatesMostProbablePath")
        
        /**
         A key in the user info dictionary of a `Notification.Name.electronicHorizonDidUpdatePosition` notification. The corresponding value is an array of upcoming road object distances from the user’s current location as `DistancedRoadObject` values. */
        public static let distancesByRoadObjectKey: NotificationUserInfoKey = .init(rawValue: "distancesByRoadObject")
        
        /**
         A key in the user info dictionary of a `Notification.Name.electronicHorizonDidEnterRoadObject` or `Notification.Name.electronicHorizonDidExitRoadObject` notification. The corresponding value is a `RoadObject.Identifier` identifying the road object that the user entered or exited. */
        public static let roadObjectIdentifierKey: NotificationUserInfoKey = .init(rawValue: "roadObjectIdentifier")
        
        /**
         A key in the user info dictionary of a `Notification.Name.electronicHorizonDidEnterRoadObject` or `Notification.Name.electronicHorizonDidExitRoadObject` notification. The corresponding value is an `NSNumber` containing a Boolean value set to `true` if the user entered at the beginning or exited at the end of the road object, or `false` if they entered or exited somewhere along the road object. */
        public static let didTransitionAtEndpointKey: NotificationUserInfoKey = .init(rawValue: "didTransitionAtEndpoint")
    }
}

public extension Notification.Name {
    
    // MARK: Switching Navigation Tile Versions
    
    /**
     :nodoc:
     Posted when Navigator has not enough tiles for map matching on current tiles version, but there are suitable older versions inside underlying Offline Regions. Navigator has restarted when this notification is issued.
     
     Such action invalidates all existing matched `RoadObject`s which should be re-applied manually.
     
     The user info dictionary contains the key `Navigator.NotificationUserInfoKey.tilesVersionKey`
    */
    static let navigationDidSwitchToFallbackVersion: Notification.Name = .init(rawValue: "NavigatorDidFallbackToOfflineVersion")
    
    /**
     :nodoc:
     Posted when Navigator was switched to a fallback offline tiles version, but latest tiles became available again. Navigator has restarted when this notification is issued.
     
     Such action invalidates all existing matched `RoadObject`s which should be re-applied manually.
     
     The user info dictionary contains the key `Navigator.NotificationUserInfoKey.tilesVersionKey`
     */
    static let navigationDidSwitchToTargetVersion: Notification.Name = .init(rawValue: "NavigatorDidRestoreToOnlineVersion")
    
    /**
     Posted when NavNative sends updated navigation status.
     
     The user info dictionary contains the keys `Navigator.NotificationUserInfoKey.originKey` and `Navigator.NotificationUserInfoKey.statusKey`.
    */
    internal static let navigationStatusDidChange: Notification.Name = .init(rawValue: "NavigationStatusDidChange")
}

extension Navigator {
    /**
     Keys in the user info dictionaries of various notifications posted by instances of `Navigator`.
     */
    public struct NotificationUserInfoKey: Hashable, Equatable, RawRepresentable {
        public typealias RawValue = String
        public var rawValue: String
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        /**
         :nodoc:
         A key in the user info dictionary of a `Notification.Name.navigationDidSwitchToFallbackVersion` or `Notification.Name.navigationDidSwitchToTargetVersion` notification. The corresponding value is a string representation of selected tiles version.
         
         For internal use only.
         */
        public static let tilesVersionKey: NotificationUserInfoKey = .init(rawValue: "tilesVersion")
        
        static let originKey: NotificationUserInfoKey = .init(rawValue: "origin")
        
        static let statusKey: NotificationUserInfoKey = .init(rawValue: "status")
    }
}
