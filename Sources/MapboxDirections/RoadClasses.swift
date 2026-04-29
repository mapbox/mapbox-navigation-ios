import Foundation

/// Option set that contains attributes of a road segment.
public struct RoadClasses: OptionSet, CustomStringConvertible, Sendable, Equatable {
    public var rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// The road segment is [tolled](https://wiki.openstreetmap.org/wiki/Key:toll).
    ///
    /// This option can only be used with ``RouteOptions/roadClassesToAvoid``.
    public static let toll = RoadClasses(rawValue: 1 << 1)

    /// The road segment has access restrictions.
    ///
    /// A road segment may have this class if there are [general access
    /// restrictions](https://wiki.openstreetmap.org/wiki/Key:access) or a [high-occupancy
    /// vehicle](https://wiki.openstreetmap.org/wiki/Key:hov) restriction.
    ///
    /// This option **cannot** be used with ``RouteOptions/roadClassesToAvoid`` or ``RouteOptions/roadClassesToAllow``.
    public static let restricted = RoadClasses(rawValue: 1 << 2)

    /// The road segment is a [freeway](https://wiki.openstreetmap.org/wiki/Tag:highway%3Dmotorway) or [freeway
    /// ramp](https://wiki.openstreetmap.org/wiki/Tag:highway%3Dmotorway_link).
    ///
    /// It may be desirable to suppress the name of the freeway when giving instructions and give instructions at fixed
    /// distances before an exit (such as 1 mile or 1 kilometer ahead).
    ///
    /// This option can only be used with ``RouteOptions/roadClassesToAvoid``.
    public static let motorway = RoadClasses(rawValue: 1 << 3)

    /// The user must travel this segment of the route by ferry.
    ///
    /// The user should verify that the ferry is in operation. For driving and cycling directions, the user should also
    /// verify that their vehicle is permitted onboard the ferry.
    ///
    /// In general, the transport type of the step containing the road segment is also ``TransportType/ferry``.
    ///
    /// This option can only be used with ``RouteOptions/roadClassesToAvoid``.
    public static let ferry = RoadClasses(rawValue: 1 << 4)

    /// The user must travel this segment of the route through a
    /// [tunnel](https://wiki.openstreetmap.org/wiki/Key:tunnel).
    ///
    /// This option **cannot** be used with ``RouteOptions/roadClassesToAvoid`` or ``RouteOptions/roadClassesToAllow``.
    public static let tunnel = RoadClasses(rawValue: 1 << 5)

    /// The road segment is a [high occupancy vehicle road](https://wiki.openstreetmap.org/wiki/Key:hov) that requires a
    /// minimum of two vehicle occupants.
    ///
    /// This option includes high occupancy vehicle road segments that require a minimum of two vehicle occupants only,
    /// not high occupancy vehicle lanes.
    /// If the user is in a high-occupancy vehicle with two occupants and would accept a route that uses a [high
    /// occupancy toll road](https://wikipedia.org/wiki/High-occupancy_toll_lane), specify both
    /// ``RoadClasses/highOccupancyVehicle2`` and ``RoadClasses/highOccupancyToll``. Otherwise, the routes will avoid
    /// any road that requires anyone to pay a toll.
    ///
    /// This option can only be used with ``RouteOptions/roadClassesToAllow``.
    public static let highOccupancyVehicle2 = RoadClasses(rawValue: 1 << 6)

    /// The road segment is a [high occupancy vehicle road](https://wiki.openstreetmap.org/wiki/Key:hov) that requires a
    /// minimum of three vehicle occupants.
    ///
    /// This option includes high occupancy vehicle road segments that require a minimum of three vehicle occupants
    /// only, not high occupancy vehicle lanes.
    ///
    /// This option can only be used with ``RouteOptions/roadClassesToAllow``.
    public static let highOccupancyVehicle3 = RoadClasses(rawValue: 1 << 7)

    /// The road segment is a [high occupancy toll road](https://wikipedia.org/wiki/High-occupancy_toll_lane) that is
    /// tolled if the user's vehicle does not meet the minimum occupant requirement.
    ///
    /// This option includes high occupancy toll road segments only, not high occupancy toll lanes.
    ///
    /// This option can only be used with ``RouteOptions/roadClassesToAllow``.
    public static let highOccupancyToll = RoadClasses(rawValue: 1 << 8)

    /// The user must travel this segment of the route on an unpaved road.
    ///
    /// This option can only be used with ``RouteOptions/roadClassesToAvoid``.
    public static let unpaved = RoadClasses(rawValue: 1 << 9)

    /// The road segment is [tolled](https://wiki.openstreetmap.org/wiki/Key:toll) and only accepts cash payment.
    ///
    /// This option can only be used with ``RouteOptions/roadClassesToAvoid``.
    public static let cashTollOnly = RoadClasses(rawValue: 1 << 10)

    /// Creates a ``RoadClasses`` given an array of strings.
    public init?(descriptions: [String]) {
        var roadClasses: RoadClasses = []
        for description in descriptions {
            switch description {
            case "toll":
                roadClasses.insert(.toll)
            case "restricted":
                roadClasses.insert(.restricted)
            case "motorway":
                roadClasses.insert(.motorway)
            case "ferry":
                roadClasses.insert(.ferry)
            case "tunnel":
                roadClasses.insert(.tunnel)
            case "hov2":
                roadClasses.insert(.highOccupancyVehicle2)
            case "hov3":
                roadClasses.insert(.highOccupancyVehicle3)
            case "hot":
                roadClasses.insert(.highOccupancyToll)
            case "unpaved":
                roadClasses.insert(.unpaved)
            case "cash_only_tolls":
                roadClasses.insert(.cashTollOnly)
            case "":
                continue
            default:
                return nil
            }
        }
        self.init(rawValue: roadClasses.rawValue)
    }

    public var description: String {
        var descriptions: [String] = []
        if contains(.toll) {
            descriptions.append("toll")
        }
        if contains(.restricted) {
            descriptions.append("restricted")
        }
        if contains(.motorway) {
            descriptions.append("motorway")
        }
        if contains(.ferry) {
            descriptions.append("ferry")
        }
        if contains(.tunnel) {
            descriptions.append("tunnel")
        }
        if contains(.highOccupancyVehicle2) {
            descriptions.append("hov2")
        }
        if contains(.highOccupancyVehicle3) {
            descriptions.append("hov3")
        }
        if contains(.highOccupancyToll) {
            descriptions.append("hot")
        }
        if contains(.unpaved) {
            descriptions.append("unpaved")
        }
        if contains(.cashTollOnly) {
            descriptions.append("cash_only_tolls")
        }
        return descriptions.joined(separator: ",")
    }
}

extension RoadClasses: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description.components(separatedBy: ",").filter { !$0.isEmpty })
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let descriptions = try container.decode([String].self)
        if let roadClasses = RoadClasses(descriptions: descriptions) {
            self = roadClasses
        } else {
            throw DirectionsError.invalidResponse(nil)
        }
    }
}
