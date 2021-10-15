import Foundation
import MapboxNavigationNative

extension RoadGraph {

    /**
     An edge in a routing graph. For example, an edge may represent a road segment between two intersections or between the two ends of a bridge. An edge may traverse multiple road objects, and a road object may be associated with multiple edges.

     An electronic horizon is a probable path (or paths) of a vehicle. The road network ahead of the user is represented as a tree of edges. Each intersection has outlet edges. In turn, each edge has a probability of transition to another edge, as well as details about the road segment that the edge traverses. You can use these details to influence application behavior based on predicted upcoming conditions.

     During active turn-by-turn navigation, the user-selected route and its metadata influence the path of the electronic horizon determined by `RouteController`. During passive navigation (free-driving), no route is actively selected, so `PassiveLocationManager` will determine the most probable path from the vehicle’s current location. You can receive notifications about changes in the current state of the electronic horizon by observing the `Notification.Name.electronicHorizonDidUpdatePosition`, `Notification.Name.electronicHorizonDidEnterRoadObject`, and `Notification.Name.electronicHorizonDidExitRoadObject` notifications.

     Use a `RoadGraph` object to get an edge with a given identifier.
     
     - note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the feature.
     */
    public struct Edge {
        /**
         Unique identifier of a directed edge.

         Use a `RoadGraph` object to get more information about the edge with a given identifier.
         */
        public typealias Identifier = UInt

        /** Unique identifier of the directed edge. */
        public let identifier: Identifier

        /**
         The level of the edge.

         A value of 0 indicates that the edge is part of the most probable path (MPP), a value of 1 indicates an edge that branches away from the MPP, and so on.
         */
        public let level: UInt

        /**
         The probability that the user will transition onto this edge, with 1 being certain and 0 being unlikely.
         */
        public let probability: Double

        /**
         The edges to which the user could transition from this edge.

         The most probable path may be split at some point if some of edges have a low probability difference (±0.05). For example, `outletEdges` can contain more than one edge with `level` set to 0. Currently, there is a maximum limit of one split per electronic horizon.
         */
        public let outletEdges: [Edge]

        /**
         Initializes a new `Edge` object.
         
         - parameter identifier: The unique identifier of a directed edge.
         - parameter level: The level of the edge.
         - parameter probability: The probability that the user will transition onto this edge.
         - parameter outletEdges: The edges to which the user could transition from this edge.
         */
        public init(identifier: Identifier, level: UInt, probability: Double, outletEdges: [Edge]) {
            self.identifier = identifier
            self.level = level
            self.probability = probability
            self.outletEdges = outletEdges
        }

        init(_ native: ElectronicHorizonEdge) {
            self.identifier = UInt(native.id)
            self.level = UInt(native.level)
            self.probability = native.probability
            self.outletEdges = native.out.map(Edge.init)
        }
    }
}
