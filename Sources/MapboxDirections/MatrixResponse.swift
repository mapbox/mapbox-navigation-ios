import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Turf

public struct MatrixResponse: Sendable {
    public typealias DistanceMatrix = [[LocationDistance?]]
    public typealias DurationMatrix = [[TimeInterval?]]

    public let httpResponse: HTTPURLResponse?

    public let destinations: [Waypoint]?
    public let sources: [Waypoint]?

    /// Array of arrays that represent the distances matrix in row-major order.
    ///
    /// `distances[i][j]` gives the route distance from the `i`'th `source` to the `j`'th `destination`. The distance
    /// between the same coordinate is always `0`. Distance from `i` to `j` is not always the same as from `j` to `i`.
    /// If a route cannot be found, the result is `nil`.
    ///
    /// - SeeAlso: ``distance(from:to:)``
    public let distances: DistanceMatrix?

    /// Array of arrays that represent the travel times matrix in row-major order.
    ///
    /// `travelTimes[i][j]` gives the travel time from the `i`'th `source` to the `j`'th `destination`. The duration
    /// between the same coordinate is always `0`. Travel time from `i` to `j` is not always the same as from `j` to
    /// `i`. If a duration cannot be found, the result is `nil`.
    ///
    /// - SeeAlso: ``travelTime(from:to:)``
    public let travelTimes: DurationMatrix?

    /// Returns route distance between specified source and destination.
    /// - Parameters:
    ///   - sourceIndex: Index of a waypoint in the ``sources`` array.
    ///   - destinationIndex: Index of a waypoint in the ``destinations`` array.
    /// - Returns: Calculated route distance between the points or `nil` if it is not available.
    public func distance(from sourceIndex: Int, to destinationIndex: Int) -> LocationDistance? {
        guard sources?.indices.contains(sourceIndex) ?? false,
              destinations?.indices.contains(destinationIndex) ?? false
        else {
            return nil
        }
        return distances?[sourceIndex][destinationIndex]
    }

    /// Returns expected travel time between specified source and destination.
    /// - Parameters:
    ///   - sourceIndex: Index of a waypoint in the ``sources`` array.
    ///   - destinationIndex: Index of a waypoint in the ``destinations`` array.
    /// - Returns: Calculated expected travel time between the points or `nil` if it is not available.
    public func travelTime(from sourceIndex: Int, to destinationIndex: Int) -> TimeInterval? {
        guard sources?.indices.contains(sourceIndex) ?? false,
              destinations?.indices.contains(destinationIndex) ?? false
        else {
            return nil
        }
        return travelTimes?[sourceIndex][destinationIndex]
    }
}

extension MatrixResponse: Codable {
    enum CodingKeys: String, CodingKey {
        case distances
        case durations
        case destinations
        case sources
    }

    public init(
        httpResponse: HTTPURLResponse?,
        distances: DistanceMatrix?,
        travelTimes: DurationMatrix?,
        destinations: [Waypoint]?,
        sources: [Waypoint]?
    ) {
        self.httpResponse = httpResponse
        self.destinations = destinations
        self.sources = sources
        self.distances = distances
        self.travelTimes = travelTimes
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var distancesMatrix: DistanceMatrix = []
        var durationsMatrix: DurationMatrix = []

        self.httpResponse = decoder.userInfo[.httpResponse] as? HTTPURLResponse
        self.destinations = try container.decode([Waypoint].self, forKey: .destinations)
        self.sources = try container.decode([Waypoint].self, forKey: .sources)

        if let decodedDistances = try container.decodeIfPresent([[Double?]].self, forKey: .distances) {
            decodedDistances.forEach { distanceArray in
                var distances: [LocationDistance?] = []
                distanceArray.forEach { distance in
                    distances.append(distance)
                }
                distancesMatrix.append(distances)
            }
            self.distances = distancesMatrix
        } else {
            self.distances = nil
        }

        if let decodedDurations = try container.decodeIfPresent([[Double?]].self, forKey: .durations) {
            decodedDurations.forEach { durationArray in
                var durations: [TimeInterval?] = []
                durationArray.forEach { duration in
                    durations.append(duration)
                }
                durationsMatrix.append(durations)
            }
            self.travelTimes = durationsMatrix
        } else {
            self.travelTimes = nil
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(destinations, forKey: .destinations)
        try container.encode(sources, forKey: .sources)
        try container.encodeIfPresent(distances, forKey: .distances)
        try container.encodeIfPresent(travelTimes, forKey: .durations)
    }
}
