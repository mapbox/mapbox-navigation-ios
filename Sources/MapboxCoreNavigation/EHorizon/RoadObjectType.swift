import Foundation
import MapboxDirections
import MapboxNavigationNative

/** Type of the road object */
public enum RoadObjectType {

    /** Road object represents some road incident */
    case incident(Incident?)

    /** Road object represents some toll collection point */
    case tollCollection(TollCollection?)

    /** Road object represents some border crossing */
    case borderCrossing(BorderCrossing?)

    /** Road object represents some tunnel entrance */
    case tunnelEntrance(Tunnel?)

    /** Road object represents some tunnel exit */
    case tunnelExit(Tunnel?)

    /** Road object represents some service area */
    case serviceArea(RestStop?)

    /** Road object represents some restricted area entrance */
    case restrictedAreaEntrance

    /** Road object represents some restricted area exit */
    case restrictedAreaExit

    /** Road object represents some bridge entrance */
    case bridgeEntrance

    /** Road object represents some bridge exit */
    case bridgeExit

    /** Reserved for future use. */
    case userDefined

    init(_ native: MapboxNavigationNative.RoadObjectType) {
        switch native {
        case .incident:
            self = .incident(nil)
        case .tollCollectionPoint:
            self = .tollCollection(nil)
        case .borderCrossing:
            self = .borderCrossing(nil)
        case .tunnelEntrance:
            self = .tunnelEntrance(nil)
        case .tunnelExit:
            self = .tunnelExit(nil)
        case .serviceArea:
            self = .serviceArea(nil)
        case .restrictedAreaEntrance:
            self = .restrictedAreaEntrance
        case .restrictedAreaExit:
            self = .restrictedAreaExit
        case .bridgeEntrance:
            self = .bridgeEntrance
        case .bridgeExit:
            self = .bridgeExit
        case .custom:
            self = .userDefined
        }
    }
}
