import Foundation
import Turf
import MapboxNavigationNative

extension RoadGraph {

    /**
     The `SubgraphEdge` represents an edge in the complex object which might be considered as a directed graph. The graph might contain loops. `innerEdgeIds` and `outerEdgeIds` properties contain edge ids, which allows to traverse the graph, obtain geometry and calculate different distances inside it.
     
     - note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the feature.
     */
    public struct SubgraphEdge {

        /**
         Unique identifier of an edge.

         Use a `RoadGraph` object to get more information about the edge with a given identifier.
         */
        public typealias Identifier = Edge.Identifier

        /** Unique identifier of the edge. */
        public let identifier: Identifier

        /** The identifiers of edges in the subgraph from which the user could transition to this edge. */
        public let innerEdgeIds: [Identifier]

        /** The identifiers of edges in the subgraph to which the user could transition from this edge. */
        public let outerEdgeIds: [Identifier]

        /** The length of the edge mesured in meters. */
        public let length: CLLocationDistance

        /** The edge shape geometry. */
        public let shape: Turf.Geometry

        /**
         Initializes a new `SubgraphEdge` object.

         - parameter identifier: The unique identifier of an edge.
         - parameter innerEdgeIds: The edges from which the user could transition to this edge.
         - parameter outerEdgeIds: The edges to which the user could transition from this edge.
         - parameter length: The length of the edge mesured in meters.
         - parameter shape: The edge shape geometry.
         */
        public init(identifier: Identifier, innerEdgeIds: [Identifier], outerEdgeIds: [Identifier], length: CLLocationDistance, shape: Turf.Geometry) {
            self.identifier = identifier
            self.innerEdgeIds = innerEdgeIds
            self.outerEdgeIds = outerEdgeIds
            self.length = length
            self.shape = shape
        }

        init(_ native: MapboxNavigationNative.SubgraphEdge) {
            self.identifier = UInt(native.id)
            self.innerEdgeIds = native.innerEdgeIds.map(UInt.init(truncating:))
            self.outerEdgeIds = native.outerEdgeIds.map(UInt.init(truncating:))
            self.length = native.length
            self.shape = Turf.Geometry(native.shape)
        }
    }
}
