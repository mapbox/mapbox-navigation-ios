import Foundation
import MapboxNavigationNative

/** Declares position of an object on the map graph */
public struct EHorizonGraphPosition {

    /** Edge id in road graph */
    public let edgeId: UInt

    /** Percent along edge shape (0-1) */
    public let percentAlong: Double

    init(_ native: GraphPosition) {
        self.edgeId = UInt(native.edgeId)
        self.percentAlong = native.percentAlong
    }
}
