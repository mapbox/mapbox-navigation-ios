import Foundation
import MapboxNavigationNative

/**
 Represents location of road object on road graph.
 
 A point object is represented by a single edge whose location has the same `fractionFromStart` and `fractionToEnd`.
 */
public struct RoadObjectEdgeLocation {

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
     Initializes a new `RoadObjectEdgeLocation` object with a fraction from the start and a fraction from the end of the road object.
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
