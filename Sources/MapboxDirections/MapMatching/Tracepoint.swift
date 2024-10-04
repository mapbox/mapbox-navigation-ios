import Foundation
import Turf
#if canImport(CoreLocation)
import CoreLocation
#endif

extension Match {
    /// A tracepoint represents a location matched to the road network.
    public struct Tracepoint: Codable, Equatable, Sendable {
        private enum CodingKeys: String, CodingKey {
            case coordinate = "location"
            case countOfAlternatives = "alternatives_count"
            case name
            case matchingIndex = "matchings_index"
            case waypointIndex = "waypoint_index"
        }

        /// The geographic coordinate of the waypoint, snapped to the road network.
        public var coordinate: LocationCoordinate2D

        /// Number of probable alternative matchings for this tracepoint. A value of zero indicates that this point was
        /// matched unambiguously.
        public var countOfAlternatives: Int

        /// The name of the road or path the coordinate snapped to.
        public var name: String?

        /// The index of the match object in matchings that the sub-trace was matched to.
        public var matchingIndex: Int

        /// The index of the waypoint inside the matched route.
        ///
        /// This value is set to`nil` for the silent waypoint when the corresponding waypoint has
        /// ``Waypoint/separatesLegs`` set to `false`.
        public var waypointIndex: Int?

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.coordinate = try container.decode(
                LocationCoordinate2DCodable.self,
                forKey: .coordinate
            ).decodedCoordinates
            self.countOfAlternatives = try container.decode(Int.self, forKey: .countOfAlternatives)
            self.name = try container.decodeIfPresent(String.self, forKey: .name)
            self.matchingIndex = try container.decode(Int.self, forKey: .matchingIndex)
            self.waypointIndex = try container.decodeIfPresent(Int.self, forKey: .waypointIndex)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(LocationCoordinate2DCodable(coordinate), forKey: .coordinate)
            try container.encode(countOfAlternatives, forKey: .countOfAlternatives)
            try container.encode(name, forKey: .name)
            try container.encode(matchingIndex, forKey: .matchingIndex)
            try container.encode(waypointIndex, forKey: .waypointIndex)
        }

        public init(
            coordinate: LocationCoordinate2D,
            countOfAlternatives: Int,
            name: String? = nil,
            matchingIndex: Int = 0,
            waypointIndex: Int = 0
        ) {
            self.coordinate = coordinate
            self.countOfAlternatives = countOfAlternatives
            self.name = name
            self.matchingIndex = matchingIndex
            self.waypointIndex = waypointIndex
        }
    }
}

extension Match.Tracepoint: CustomStringConvertible {
    public var description: String {
        return "<latitude: \(coordinate.latitude); longitude: \(coordinate.longitude)>"
    }
}
