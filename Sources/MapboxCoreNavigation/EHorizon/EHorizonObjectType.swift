import Foundation
import MapboxNavigationNative

public enum EHorizonObjectType {

    /** Road object represents some road incident */
    case incident

    /** Road object represents some toll collection point */
    case tollCollectionPoint

    /** Road object represents some border crossing */
    case borderCrossing

    /** Road object represents some tunnel entrance */
    case tunnelEntrance

    /** Road object represents some tunnel exit */
    case tunnelExit

    /** Road object represents some restricted area entrance */
    case restrictedAreaEntrance

    /** Road object represents some restricted area exit */
    case restrictedAreaExit

    /** Road object represents some service area */
    case serviceArea

    /** Road object represents some bridge entrance */
    case bridgeEntrance

    /** Road object represents some bridge exit */
    case bridgeExit

    /** Road object was added by user(via `RoadObjectsStore.addCustomRoadObject`) */
    case custom

    init(_ native: RoadObjectType) {
        switch native {
        case .incident:
            self = .incident
        case .tollCollectionPoint:
            self = .tollCollectionPoint
        case .borderCrossing:
            self = .borderCrossing
        case .tunnelEntrance:
            self = .tunnelEntrance
        case .tunnelExit:
            self = .tunnelExit
        case .restrictedAreaEntrance:
            self = .restrictedAreaEntrance
        case .restrictedAreaExit:
            self = .restrictedAreaExit
        case .serviceArea:
            self = .serviceArea
        case .bridgeEntrance:
            self = .bridgeEntrance
        case .bridgeExit:
            self = .bridgeExit
        case .custom:
            self = .custom
        }
    }
}
