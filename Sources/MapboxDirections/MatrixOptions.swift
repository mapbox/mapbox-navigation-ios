import Foundation
import Turf

/// Options for calculating matrices from the Mapbox Matrix service.
public class MatrixOptions: Codable {
    // MARK: Creating a Matrix Options Object

    /// Initializes a matrix options object for matrices and a given profile identifier.
    /// - Parameters:
    ///   - sources: An array of ``Waypoint`` objects representing sources.
    ///   - destinations: An array of ``Waypoint`` objects representing destinations.
    ///   - profileIdentifier: A string specifying the primary mode of transportation for the routes.
    ///
    /// - Note: `sources` and `destinations` should not be empty, otherwise matrix would not make sense. Total number of
    /// waypoints may differ depending on the `profileIdentifier`. [See documentation for
    /// details](https://docs.mapbox.com/api/navigation/matrix/#matrix-api-restrictions-and-limits).
    public init(sources: [Waypoint], destinations: [Waypoint], profileIdentifier: ProfileIdentifier) {
        self.profileIdentifier = profileIdentifier
        self.waypointsData = .init(
            sources: sources,
            destinations: destinations
        )
    }

    private let waypointsData: WaypointsData

    ///  A string specifying the primary mode of transportation for the contours.
    public var profileIdentifier: ProfileIdentifier

    /// An array of ``Waypoint`` objects representing locations that will be in the matrix.
    public var waypoints: [Waypoint] {
        return waypointsData.waypoints
    }

    /// Attribute options for the matrix.
    ///
    /// Only ``AttributeOptions/distance`` and ``AttributeOptions/expectedTravelTime`` are supported. Empty
    /// `attributeOptions` will result in default
    /// values assumed.
    public var attributeOptions: AttributeOptions = []

    /// The ``Waypoint`` array that should be used as destinations.
    ///
    /// Must not be empty.
    public var destinations: [Waypoint] {
        get {
            waypointsData.destinations
        }
        set {
            waypointsData.destinations = newValue
        }
    }

    /// The ``Waypoint`` array that should be used as sources.
    ///
    /// Must not be empty.
    public var sources: [Waypoint] {
        get {
            waypointsData.sources
        }
        set {
            waypointsData.sources = newValue
        }
    }

    private enum CodingKeys: String, CodingKey {
        case profileIdentifier = "profile"
        case attributeOptions = "annotations"
        case destinations
        case sources
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(profileIdentifier, forKey: .profileIdentifier)
        try container.encode(attributeOptions, forKey: .attributeOptions)
        try container.encodeIfPresent(destinations, forKey: .destinations)
        try container.encodeIfPresent(sources, forKey: .sources)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.profileIdentifier = try container.decode(ProfileIdentifier.self, forKey: .profileIdentifier)
        self.attributeOptions = try container.decodeIfPresent(AttributeOptions.self, forKey: .attributeOptions) ?? []
        let destinations = try container.decodeIfPresent([Waypoint].self, forKey: .destinations) ?? []
        let sources = try container.decodeIfPresent([Waypoint].self, forKey: .sources) ?? []
        self.waypointsData = .init(
            sources: sources,
            destinations: destinations
        )
    }

    // MARK: Getting the Request URL

    var coordinates: String? {
        waypoints.map(\.coordinate.requestDescription).joined(separator: ";")
    }

    ///     An array of URL query items to include in an HTTP request.
    var abridgedPath: String {
        return "directions-matrix/v1/\(profileIdentifier.rawValue)"
    }

    /// The path of the request URL, not including the hostname or any parameters.
    var path: String {
        guard let coordinates,
              !coordinates.isEmpty
        else {
            assertionFailure("No query")
            return ""
        }
        return "\(abridgedPath)/\(coordinates)"
    }

    /// An array of URL query items (parameters) to include in an HTTP request.
    public var urlQueryItems: [URLQueryItem] {
        var queryItems: [URLQueryItem] = []

        if !attributeOptions.isEmpty {
            queryItems.append(URLQueryItem(name: "annotations", value: attributeOptions.description))
        }

        let mustArriveOnDrivingSide = !waypoints.filter { !$0.allowsArrivingOnOppositeSide }.isEmpty
        if mustArriveOnDrivingSide {
            let approaches = waypoints.map { $0.allowsArrivingOnOppositeSide ? "unrestricted" : "curb" }
            queryItems.append(URLQueryItem(name: "approaches", value: approaches.joined(separator: ";")))
        }

        if waypoints.count != waypointsData.destinationsIndices.count {
            let destinationString = waypointsData.destinationsIndices.map { String($0) }.joined(separator: ";")
            queryItems.append(URLQueryItem(name: "destinations", value: destinationString))
        }

        if waypoints.count != waypointsData.sourcesIndices.count {
            let sourceString = waypointsData.sourcesIndices.map { String($0) }.joined(separator: ";")
            queryItems.append(URLQueryItem(name: "sources", value: sourceString))
        }

        return queryItems
    }
}

@available(*, unavailable)
extension MatrixOptions: @unchecked Sendable {}

extension MatrixOptions: Equatable {
    public static func == (lhs: MatrixOptions, rhs: MatrixOptions) -> Bool {
        return lhs.profileIdentifier == rhs.profileIdentifier &&
            lhs.attributeOptions == rhs.attributeOptions &&
            lhs.sources == rhs.sources &&
            lhs.destinations == rhs.destinations
    }
}

extension MatrixOptions {
    fileprivate class WaypointsData {
        private(set) var waypoints: [Waypoint] = []
        var sources: [Waypoint] {
            didSet {
                updateWaypoints()
            }
        }

        var destinations: [Waypoint] {
            didSet {
                updateWaypoints()
            }
        }

        private(set) var sourcesIndices: IndexSet = []
        private(set) var destinationsIndices: IndexSet = []

        private func updateWaypoints() {
            sourcesIndices = []
            destinationsIndices = []

            var destinations = destinations
            for source in sources.enumerated() {
                for destination in destinations.enumerated() {
                    if source.element == destination.element {
                        destinations.remove(at: destination.offset)
                        destinationsIndices.insert(source.offset)
                        break
                    }
                }
            }

            destinationsIndices.insert(integersIn: sources.endIndex..<(sources.endIndex + destinations.count))

            var sum = sources
            sum.append(contentsOf: destinations)
            waypoints = sum

            sourcesIndices = IndexSet(integersIn: sources.indices)
        }

        init(sources: [Waypoint], destinations: [Waypoint]) {
            self.sources = sources
            self.destinations = destinations

            updateWaypoints()
        }
    }
}
