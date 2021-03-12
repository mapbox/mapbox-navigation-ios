import Foundation
import MapboxNavigationNative

/**
 Represents location of road object on road graph.
 For point-like objects will contain single edge with `fractionFromStart == fractionToEnd`
 */
public struct RoadObjectEdgeLocation {

    /**
     Offset from the start of edge (0 - 1) pointing to the beginning of road object on this edge
     will be 0 for all edges in the line-like road object except the very first one
     in the case of point-like object fractionFromStart == fractionToEnd
     */
    public let percentAlongBegin: Double

    /**
     Offset from the start of edge (0 - 1) pointing to the end of road object on this edge
     will be 1 for all edges in the line-like road object except the very first one
     in the case of point-like object fractionFromStart == fractionToEnd
     */
    public let percentAlongEnd: Double

    init(_ native: MapboxNavigationNative.RoadObjectEdgeLocation) {
        self.percentAlongBegin = native.percentAlongBegin
        self.percentAlongEnd = native.percentAlongEnd
    }
}
