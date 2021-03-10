import Foundation
import CoreLocation
import MapboxNavigationNative

/** A position along a linear object in the road graph. */
public struct EHorizonGraphPath {
    /** The edge identifiers that form the linear object. */
    public let edgeIdentifiers: [EHorizonEdge.Identifier]

    /** Percent along edge shape (0-1) of a path begin point. */
    public let percentAlongBegin: Double

    /** Percent along edge shape (0-1) of a path end point. */
    public let percentAlongEnd: Double
    
    /** Length of a path. */
    public let length: CLLocationDistance

    init(_ native: GraphPath) {
        self.edgeIdentifiers = native.edges.map { $0.uintValue }
        self.percentAlongBegin = native.percentAlongBegin
        self.percentAlongEnd = native.percentAlongEnd
        self.length = native.length
    }
}
