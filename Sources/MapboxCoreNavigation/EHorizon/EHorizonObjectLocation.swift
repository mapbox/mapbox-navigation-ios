import Foundation
import MapboxNavigationNative

/**
 Represents location of road object on road graph for point-like objects
 will contain single edge with `percentAlongBegin == percentAlongEnd`
 */
public struct EHorizonObjectLocation {

    /** List of edge ids belong to object */
    public let edges: [UInt]

    /** Offset from the start of edge (0 - 1) pointing to the start of road object on the very first edge */
    public let percentAlongBegin: Double

    /** Offset from the start of edge (0 - 1) pointing to the end of road object on the very last edge */
    public let percentAlongEnd: Double

    init(_ native: RoadObjectLocation) {
        self.edges = native.edges.map { $0.uintValue }
        self.percentAlongBegin = native.percentAlongBegin
        self.percentAlongEnd = native.percentAlongEnd
    }
}
