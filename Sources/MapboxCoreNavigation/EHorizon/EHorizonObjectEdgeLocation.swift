import Foundation
import MapboxNavigationNative

public struct EHorizonObjectEdgeLocation {
    /**
     Offset from the start of edge (0 - 1) pointing to the beginning of road object on this edge
     will be 0 for all edges in the line-like road object expect the very first one
     in the case of point-like object percentAlongBegin == percentAlongEnd
     */
    public let percentAlongBegin: Double

    /**
     Offset from the start of edge (0 - 1) pointing to the end of road object on this edge
     will be 1 for all edges in the line-like road object expect the very first one
     in the case of point-like object percentAlongBegin == percentAlongEnd
     */
    public let percentAlongEnd: Double

    init(_ native: RoadObjectEdgeLocation) {
        self.percentAlongBegin = native.percentAlongBegin
        self.percentAlongEnd = native.percentAlongEnd
    }
}
