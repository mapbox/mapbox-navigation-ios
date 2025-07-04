import CoreLocation
import Foundation
import MapboxNavigationNative_Private

extension RoadGraph {
    /// A position along a linear object in the road graph.
    ///
    /// - Note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to
    /// changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox
    /// Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and
    /// require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level
    /// of use of the feature.
    public struct Path: Equatable, Sendable {
        /// The edge identifiers that fully or partially coincide with the linear object.
        public let edgeIdentifiers: [Edge.Identifier]

        /// The distance from the start of an edge to the start of the linear object as a fraction of the edge’s length
        /// from 0 to 1.
        public let fractionFromStart: Double

        /// The distance from the end of the linear object to the end of an edge as a fraction of the edge’s length from
        /// 0 to 1.
        public let fractionToEnd: Double

        /// Length of a path, measured in meters.
        public let length: CLLocationDistance

        /// Initializes a new ``RoadGraph/Path`` object.
        /// - Parameters:
        ///   - edgeIdentifiers: An `Array` of edge identifiers that fully or partially coincide with the linear object.
        ///   - fractionFromStart: The distance from the start of an edge to the start of the linear object as a
        /// fraction of the edge's length from 0 to 1.
        ///   - fractionToEnd: The distance from the end of the linear object to the edge of the edge as a fraction of
        /// the edge's length from 0 to 1.
        ///   - length: Length of a ``RoadGraph/Path`` measured in meters.
        public init(
            edgeIdentifiers: [RoadGraph.Edge.Identifier],
            fractionFromStart: Double,
            fractionToEnd: Double,
            length: CLLocationDistance
        ) {
            self.edgeIdentifiers = edgeIdentifiers
            self.fractionFromStart = fractionFromStart
            self.fractionToEnd = fractionToEnd
            self.length = length
        }

        init(_ native: GraphPath) {
            self.edgeIdentifiers = native.edges.map(\.uintValue)
            self.fractionFromStart = native.percentAlongBegin
            self.fractionToEnd = native.percentAlongEnd
            self.length = native.length
        }
    }
}

extension GraphPath {
    convenience init(_ path: RoadGraph.Path) {
        self.init(
            edges: path.edgeIdentifiers.map { NSNumber(value: $0) },
            percentAlongBegin: path.fractionFromStart,
            percentAlongEnd: path.fractionToEnd,
            length: path.length
        )
    }
}
