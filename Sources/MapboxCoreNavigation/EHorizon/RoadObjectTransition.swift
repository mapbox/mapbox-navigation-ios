import Foundation
import MapboxNavigationNative

/** Represents information about road object transitions */
public struct RoadObjectTransition {

    /** Road object identifier */
    public let roadObjectIdentifier: RoadObjectIdentifier

    /**
     If object was entered via it's start for `onRoadObjectEnter`
     or if object was exited via it's end for `onRoadObjectExit`
     */
    public let isEnterFromStartOrExitFromEnd: Bool

    /** Type of road object */
    public let type: RoadObjectType

    init(_ native: RoadObjectEnterExitInfo) {
        self.roadObjectIdentifier = native.roadObjectId
        self.isEnterFromStartOrExitFromEnd = native.isEnterFromStartOrExitFromEnd
        self.type = RoadObjectType(native.type)
    }
}
