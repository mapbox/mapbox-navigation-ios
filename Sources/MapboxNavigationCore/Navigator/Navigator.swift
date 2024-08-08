import Combine
import CoreLocation
import MapboxDirections
import MapboxNavigationNative

// MARK: - NavigationEvent

/// The base for all ``MapboxNavigation`` events.
public protocol NavigationEvent: Equatable, Sendable {}
extension NavigationEvent {
    fileprivate func compare(to other: any NavigationEvent) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }
}

// MARK: - SessionState

/// Navigation session details.
public struct Session: Equatable, Sendable {
    /// Current session state.
    public let state: State

    /// Describes possible navigation states.
    public enum State: Equatable, Sendable {
        /// The navigator is idle and is not tracking user location.
        case idle
        /// The navigator observes user location and matches it to the road network.
        case freeDrive(FreeDriveState) // MBNNRouteStateInvalid *
        /// The navigator tracks user progress along the given route.
        case activeGuidance(ActiveGuidanceState)

        /// Flags if navigator is currently active.
        public var isTripSessionActive: Bool {
            return self != .idle
        }

        /// Describes possible Free Drive states
        public enum FreeDriveState: Sendable {
            /// Free drive is paused.
            ///
            /// The navigator does not currently tracks user location, but can be resumed any time.
            /// Unlike switching to the ``Session/State-swift.enum/idle`` state, pausing the Free drive does not
            /// interrupt the navigation session.
            case paused
            /// The navigator observes user location and matches it to the road network.
            ///
            /// Unlike switching to the ``Session/State-swift.enum/idle`` state, pausing the Free drive does not
            /// interrupt the navigation session.
            case active
        }

        /// Describes possible Active Guidance states.
        public enum ActiveGuidanceState: Sendable {
            /// Initial state when starting a new route.
            case initialized
            /// The Navigation process is nominal.
            ///
            /// The navigator tracks user position and progress.
            case tracking // MBNNRouteStateTracking
            /// The navigator detected user went off the route.
            case offRoute // MBNNRouteStateUncertain *
            /// The navigator experiences troubles determining it's state.
            ///
            /// This may be signaled when navigator is judjing if user is still on the route or is wandering off, or
            /// when GPS signal quality has dropped, or due to some other technical conditions.
            /// Unless `offRoute` is reported - it is still treated as user progressing the route.
            case uncertain // MBNNRouteStateInitialized + MBNNRouteStateUncertain + MBNNRouteStateInvalid(?)
            /// The user has arrived to the final destination.
            case complete // MBNNRouteStateComplete

            init(_ routeState: RouteState) {
                switch routeState {
                case .invalid, .uncertain:
                    self = .uncertain
                case .initialized:
                    self = .initialized
                case .tracking:
                    self = .tracking
                case .complete:
                    self = .complete
                case .offRoute:
                    self = .offRoute
                @unknown default:
                    self = .uncertain
                }
            }
        }
    }
}

// MARK: - RouteProgressState

/// Route progress update event details.
public struct RouteProgressState: Sendable {
    /// Actual ``RouteProgress``.
    public let routeProgress: RouteProgress
}

// MARK: - MapMatchingState

/// Map matching update event details.
public struct MapMatchingState: Equatable, @unchecked Sendable {
    /// Current user raw location.
    public let location: CLLocation
    /// Current user matched location.
    public let mapMatchingResult: MapMatchingResult
    /// Actual speed limit.
    public let speedLimit: SpeedLimit
    /// Detected actual user speed.
    public let currentSpeed: Measurement<UnitSpeed>
    /// Current road name, if available.
    public let roadName: RoadName?

    /// The best possible location update, snapped to the route or map matched to the road if possible
    public var enhancedLocation: CLLocation {
        mapMatchingResult.enhancedLocation
    }
}

// MARK: - FallbackToTilesState

/// Tiles fallback update event details.
public struct FallbackToTilesState: Equatable, Sendable {
    /// Flags if the Navigator is currently using latest known tiles version.
    public let usingLatestTiles: Bool
}

// MARK: - SpokenInstructionState

/// Voice instructions update event details.
public struct SpokenInstructionState: Equatable, Sendable {
    /// Actual ``SpokenInstruction`` to be pronounced.
    public let spokenInstruction: SpokenInstruction
}

// MARK: - VisualInstructionState

/// Visual instructions update event details.
public struct VisualInstructionState: Equatable, Sendable {
    /// Actual visual instruction to be displayed.
    public let visualInstruction: VisualInstructionBanner
}

// MARK: - WaypointArrivalStatus

/// The base for all ``WaypointArrivalStatus`` events.
public protocol WaypointArrivalEvent: NavigationEvent {}

/// Waypoint arrival update event details.
public struct WaypointArrivalStatus: Equatable, Sendable {
    public static func == (lhs: WaypointArrivalStatus, rhs: WaypointArrivalStatus) -> Bool {
        lhs.event.compare(to: rhs.event)
    }

    /// Actual event details.
    ///
    /// See ``WaypointArrivalEvent`` implementations for possible event types.
    public let event: any WaypointArrivalEvent

    public enum Events {
        /// User has arrived to the final destination.
        public struct ToFinalDestination: WaypointArrivalEvent, @unchecked Sendable {
            /// Final destination waypoint.
            public let destination: Waypoint
        }

        /// User has arrived to the intermediate waypoint.
        public struct ToWaypoint: WaypointArrivalEvent, @unchecked Sendable {
            /// The waypoint user has arrived to.
            public let waypoint: Waypoint
            /// Waypoint's leg index.
            public let legIndex: Int
        }

        /// Next leg navigation has started.
        public struct NextLegStarted: WaypointArrivalEvent, @unchecked Sendable {
            /// New actual leg index in the route.
            public let newLegIndex: Int
        }
    }
}

// MARK: - ReroutingStatus

/// The base for all ``ReroutingStatus`` events.
public protocol ReroutingEvent: NavigationEvent {}

/// Rerouting update event details.
public struct ReroutingStatus: Equatable, Sendable {
    public static func == (lhs: ReroutingStatus, rhs: ReroutingStatus) -> Bool {
        lhs.event.compare(to: rhs.event)
    }

    /// Actual event details.
    ///
    /// See ``ReroutingEvent`` implementations for possible event types.
    public let event: any ReroutingEvent

    public enum Events {
        /// Reroute event was triggered and SDK is currently fetching a new route.
        public struct FetchingRoute: ReroutingEvent, Sendable {}
        /// The reroute process was manually interrupted.
        public struct Interrupted: ReroutingEvent, Sendable {}
        /// The reroute process has failed with an error.
        public struct Failed: ReroutingEvent, Sendable {
            /// The underlying error.
            public let error: DirectionsError
        }

        /// The reroute process has successfully fetched a route and completed the process.
        public struct Fetched: ReroutingEvent, Sendable {}
    }
}

// MARK: - AlternativesStatus

/// The base for all ``AlternativesStatus`` events.
public protocol AlternativesEvent: NavigationEvent {}

/// Continuous alternatives update event details.
public struct AlternativesStatus: Equatable, Sendable {
    public static func == (lhs: AlternativesStatus, rhs: AlternativesStatus) -> Bool {
        lhs.event.compare(to: rhs.event)
    }

    /// Actual event details.
    ///
    /// See ``AlternativesEvent`` implementations for possible event types.
    public let event: any AlternativesEvent

    public enum Events {
        /// The list of actual continuous alternatives was updated.
        public struct Updated: AlternativesEvent, Sendable {
            /// Currently actual list of alternative routes.
            public let actualAlternativeRoutes: [AlternativeRoute]
        }

        /// The navigator switched to the alternative route. The previous main route is an alternative now.
        public struct SwitchedToAlternative: AlternativesEvent, Sendable {
            /// The current navigation routes after switching to the alternative route.
            public let navigationRoutes: NavigationRoutes
        }
    }
}

// MARK: - FasterRoutesStatus

/// The base for all ``FasterRoutesStatus`` events.
public protocol FasterRoutesEvent: NavigationEvent {}

/// Faster route update event details.
public struct FasterRoutesStatus: Equatable, Sendable {
    public static func == (lhs: FasterRoutesStatus, rhs: FasterRoutesStatus) -> Bool {
        lhs.event.compare(to: rhs.event)
    }

    /// Actual event details.
    ///
    /// See ``FasterRoutesEvent`` implementations for possible event types.
    public let event: any FasterRoutesEvent

    public enum Events {
        /// The SDK has detected a faster route possibility.
        public struct Detected: FasterRoutesEvent, Sendable {}
        /// The SDK has applied the faster route.
        public struct Applied: FasterRoutesEvent, Sendable {}
    }
}

// MARK: - RefreshingStatus

/// The base for all ``RefreshingStatus`` events.
public protocol RefreshingEvent: NavigationEvent {}

/// Route refreshing update event details.
public struct RefreshingStatus: Equatable, Sendable {
    public static func == (lhs: RefreshingStatus, rhs: RefreshingStatus) -> Bool {
        lhs.event.compare(to: rhs.event)
    }

    /// Actual event details.
    ///
    /// See ``RefreshingEvent`` implementations for possible event types.
    public let event: any RefreshingEvent

    public enum Events {
        /// The route refreshing process has begun.
        public struct Refreshing: RefreshingEvent, Sendable {}
        /// The route has been refreshed.
        public struct Refreshed: RefreshingEvent, Sendable {}
        /// Indicates that current route's refreshing is no longer available.
        ///
        /// It is strongly recommended to request a new route. Refreshing TTL has expired and the route will no longer
        /// recieve refreshing updates, which may lead to suboptimal navigation experience.
        public struct Invalidated: RefreshingEvent, Sendable {
            /// The routes for which refreshing is no longer available.
            public let navigationRoutes: NavigationRoutes
        }
    }
}

// MARK: - EHorizonStatus

/// The base for all ``EHorizonStatus`` events.
public protocol EHorizonEvent: NavigationEvent {}

/// Electronic horizon update event details.
public struct EHorizonStatus: Equatable, Sendable {
    public static func == (lhs: EHorizonStatus, rhs: EHorizonStatus) -> Bool {
        lhs.event.compare(to: rhs.event)
    }

    /// Actual event details.
    ///
    /// See ``EHorizonEvent`` implementations for possible event types.
    public let event: any EHorizonEvent

    public enum Events {
        /// EH position withing the road graph has changed.
        public struct PositionUpdated: Sendable, EHorizonEvent {
            /// New EH position.
            public let position: RoadGraph.Position
            /// New starting edge of the graph
            public let startingEdge: RoadGraph.Edge
            /// Flags if MPP was updated.
            public let updatesMostProbablePath: Bool
            /// Distances for upcoming road objects.
            public let distances: [DistancedRoadObject]
        }

        /// EH position has entered a road object.
        public struct RoadObjectEntered: Sendable, EHorizonEvent {
            /// Related road object ID.
            public let roadObjectId: RoadObject.Identifier
            /// Flags if entrance was from object's beginning.
            public let enteredFromStart: Bool
        }

        /// EH position has left a road object
        public struct RoadObjectExited: Sendable, EHorizonEvent {
            /// Related road object ID.
            public let roadObjectId: RoadObject.Identifier
            /// Flags if object was left through it's ending.
            public let exitedFromEnd: Bool
        }

        /// EH position has passed point or gantry objects
        public struct RoadObjectPassed: Sendable, EHorizonEvent {
            /// Related road object ID.
            public let roadObjectId: RoadObject.Identifier
        }
    }
}

// MARK: - NavigatorError

/// The base for all ``NavigatorErrors``.
public protocol NavigatorError: Error {}

public enum NavigatorErrors {
    /// The SDK has failed to set a route to the Navigator.
    public struct FailedToSetRoute: NavigatorError {
        /// Underlying error description.
        public let underlyingError: Error?
    }

    /// Switching to the alternative route has failed.
    public struct FailedToSelectAlternativeRoute: NavigatorError {}
    /// Updating the list of alternative routes has failed.
    public struct FailedToUpdateAlternativeRoutes: NavigatorError {
        /// Localized description.
        public let localizedDescription: String
    }

    /// Switching route legs has failed.
    public struct FailedToSelectRouteLeg: NavigatorError {}
    /// Failed to switch the navigator state to `idle`.
    public struct FailedToSetToIdle: NavigatorError {}
    /// Failed to pause the free drive session.
    public struct FailedToPause: NavigatorError {}
    /// Unexpectedly received NN status when in `idle` state.
    public struct UnexpectedNavigationStatus: NavigatorError {}
    /// Rerouting process was not completed successfully.
    public struct InterruptedReroute: NavigatorError {
        /// Underlying error description.
        public let underlyingError: Error?
    }
}

// MARK: - RoadMatching

/// Description of the road graph network and related road objects.
public struct RoadMatching: Sendable {
    /// Provides access to the road tree graph.
    public let roadGraph: RoadGraph
    /// Provides access to metadata about road objects.
    public let roadObjectStore: RoadObjectStore
    /// Provides methods for road object matching.
    public let roadObjectMatcher: RoadObjectMatcher
}
