import Foundation
import MapboxNavigationNative

public struct EHorizonEdge {

    /** Unique identifier of the directed edge */
    public let identifier: UInt

    /**
     The level of the Edge (0 being the mpp, 1 branches of the mpp,
     2 branches of level 1 branches, etc)
     */
    public let level: UInt

    /** The probability for this edge in percentage */
    public let probability: Double

    /**
     The outgoing Edges.
     NB: MPP can be splitted at some point if some of edges have low probability difference(+/- 0.05),
     i.e. `out` can contain more than 1 edges with the level 0.
     Currently we have a limitation for maximum 1 split per electronic horizon.
     */
    public let outletEdges: [EHorizonEdge]

    init(_ native: ElectronicHorizonEdge) {
        self.identifier = UInt(native.id)
        self.level = UInt(native.level)
        self.probability = native.probability
        self.outletEdges = native.out.map(EHorizonEdge.init)
    }
}
