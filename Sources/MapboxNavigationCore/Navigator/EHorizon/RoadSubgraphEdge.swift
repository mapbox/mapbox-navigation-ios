import Foundation
import MapboxNavigationNative_Private
import Turf

extension RoadGraph {
    /// The ``RoadGraph/SubgraphEdge`` represents an edge in the complex object which might be considered as a directed
    /// graph. The graph might contain loops. ``innerEdgeIds`` and ``outerEdgeIds`` properties contain edge ids, which
    /// allows to traverse the graph, obtain geometry and calculate different distances inside it.
    ///
    /// - Note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to
    /// changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox
    /// Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and
    /// require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level
    /// of use of the feature.
    public struct SubgraphEdge: Equatable, Sendable {
        /// Unique identifier of an edge.
        ///
        /// Use a ``RoadGraph`` object to get more information about the edge with a given identifier.
        public typealias Identifier = Edge.Identifier

        /// Unique identifier of the edge.
        public let identifier: Identifier

        /// The identifiers of edges in the subgraph from which the user could transition to this edge.
        public let innerEdgeIds: [Identifier]

        /// The identifiers of edges in the subgraph to which the user could transition from this edge.
        public let outerEdgeIds: [Identifier]

        /// The length of the edge mesured in meters.
        public let length: CLLocationDistance

        /// The edge shape geometry.
        public let shape: Turf.Geometry

        /// Initializes a new ``RoadGraph/SubgraphEdge`` object.
        /// - Parameters:
        ///   - identifier: The unique identifier of an edge.
        ///   - innerEdgeIds: The edges from which the user could transition to this edge.
        ///   - outerEdgeIds: The edges to which the user could transition from this edge.
        ///   - length: The length of the edge mesured in meters.
        ///   - shape: The edge shape geometry.
        public init(
            identifier: Identifier,
            innerEdgeIds: [Identifier],
            outerEdgeIds: [Identifier],
            length: CLLocationDistance,
            shape: Turf.Geometry
        ) {
            self.identifier = identifier
            self.innerEdgeIds = innerEdgeIds
            self.outerEdgeIds = outerEdgeIds
            self.length = length
            self.shape = shape
        }

        init?(_ native: MapboxNavigationNative_Private.SubgraphEdge) {
            guard let shape = Turf.Geometry(native.shape) else { return nil }

            self.identifier = UInt(native.id)
            self.innerEdgeIds = native.innerEdgeIds.map(UInt.init(truncating:))
            self.outerEdgeIds = native.outerEdgeIds.map(UInt.init(truncating:))
            self.length = native.length
            self.shape = shape
        }
    }
}
