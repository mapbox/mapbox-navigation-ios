import MapboxDirections

/// Options determining the primary mode of transportation.
public typealias ProfileIdentifier = MapboxDirections.ProfileIdentifier
/// A ``Waypoint`` object indicates a location along a route. It may be the route’s origin or destination, or it may be
/// another location that the route visits. A waypoint object indicates the location’s geographic location along with
/// other optional information, such as a name or the user’s direction approaching the waypoint.
public typealias Waypoint = MapboxDirections.Waypoint
/// A ``CongestionLevel`` indicates the level of traffic congestion along a road segment relative to the normal flow of
/// traffic along that segment. You can color-code a route line according to the congestion level along each segment of
/// the route.
public typealias CongestionLevel = MapboxDirections.CongestionLevel
/// Option set that contains attributes of a road segment.
public typealias RoadClasses = MapboxDirections.RoadClasses

/// An instruction about an upcoming ``RouteStep``’s maneuver, optimized for speech synthesis.
public typealias SpokenInstruction = MapboxDirections.SpokenInstruction
///  A visual instruction banner contains all the information necessary for creating a visual cue about a given
/// ``RouteStep``.
public typealias VisualInstructionBanner = MapboxDirections.VisualInstructionBanner
/// An error that occurs when calculating directions.
public typealias DirectionsError = MapboxDirections.DirectionsError

/// A ``RouteLeg`` object defines a single leg of a route between two waypoints. If the overall route has only two
/// waypoints, it has a single ``RouteLeg`` object that covers the entire route. The route leg object includes
/// information about the leg, such as its name, distance, and expected travel time. Depending on the criteria used to
/// calculate the route, the route leg object may also include detailed turn-by-turn instructions.
public typealias RouteLeg = MapboxDirections.RouteLeg
/// A ``RouteStep`` object represents a single distinct maneuver along a route and the approach to the next maneuver.
/// The route step object corresponds to a single instruction the user must follow to complete a portion of the route.
/// For example, a step might require the user to turn then follow a road.
public typealias RouteStep = MapboxDirections.RouteStep
