import Foundation
import MapboxNavigationNative

/** Type of the road object */
public enum RoadObjectType {

    /** Road object represents some road incident */
    case incident

    /** Road object represents some toll collection point */
    case tollCollection

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

    /** Reserved for future use. */
    case userDefined

    init(_ native: MapboxNavigationNative.RoadObjectType) {
        switch native {
        case .incident:
            self = .incident
        case .tollCollectionPoint:
            self = .tollCollection
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
            self = .userDefined
        }
    }
}
