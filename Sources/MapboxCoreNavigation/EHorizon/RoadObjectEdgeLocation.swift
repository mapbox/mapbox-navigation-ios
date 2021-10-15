import Foundation
import MapboxNavigationNative

extension RoadObject {
    
    /**
     Represents location of road object on road graph.
     
     A point object is represented by a single edge whose location has the same `fractionFromStart` and `fractionToEnd`.
     
     - note: The Mapbox Electronic Horizon feature of the Mapbox Navigation SDK is in public beta and is subject to changes, including its pricing. Use of the feature is subject to the beta product restrictions in the Mapbox Terms of Service. Mapbox reserves the right to eliminate any free tier or free evaluation offers at any time and require customers to place an order to purchase the Mapbox Electronic Horizon feature, regardless of the level of use of the feature.
     */
    public struct EdgeLocation {

        /**
         Offset from the start of edge (0 - 1) pointing to the beginning of road object on this edge
         will be 0 for all edges in the line-like road object except the very first one
         in the case of point-like object fractionFromStart == fractionToEnd
         */
        public let fractionFromStart: Double

        /**
         Offset from the start of edge (0 - 1) pointing to the end of road object on this edge
         will be 1 for all edges in the line-like road object except the very first one
         in the case of point-like object fractionFromStart == fractionToEnd
         */
        public let fractionToEnd: Double

        /**
         Initializes a new `EdgeLocation` object with a fraction from the start and a fraction from the end of the road object.
         */
        public init(fractionFromStart: Double, fractionToEnd: Double) {
            self.fractionFromStart = fractionFromStart
            self.fractionToEnd = fractionToEnd
        }

        init(_ native: MapboxNavigationNative.RoadObjectEdgeLocation) {
            self.fractionFromStart = native.percentAlongBegin
            self.fractionToEnd = native.percentAlongEnd
        }
    }
}
