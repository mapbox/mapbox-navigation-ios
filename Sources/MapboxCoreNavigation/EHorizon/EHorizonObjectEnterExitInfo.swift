import Foundation
import MapboxNavigationNative

public struct EHorizonObjectEnterExitInfo {

    /** Road object id */
    public let roadObjectId: String

    /**
     If object was entered via it's start for `onRoadObjectEnter`
     or if object was exited via it's end for `onRoadObjectExit`
     */
    public let isEnterFromStartOrExitFromEnd: Bool

    /** Type of road object */
    public let type: EHorizonObjectType

    init(_ native: RoadObjectEnterExitInfo) {
        self.roadObjectId = native.roadObjectId
        self.isEnterFromStartOrExitFromEnd = native.isEnterFromStartOrExitFromEnd
        self.type = EHorizonObjectType(native.type)
    }
}
