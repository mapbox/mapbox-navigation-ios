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

    /** Road object represents some tunnel */
    case tunnel(Tunnel?)

    /** Road object represents some service area */
    case serviceArea(RestStop?)

    /** Road object represents some restricted area */
    case restrictedArea

    /** Road object represents some bridge */
    case bridge

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
        case .tunnel:
            self = .tunnel(nil)
        case .serviceArea:
            self = .serviceArea(nil)
        case .restrictedArea:
            self = .restrictedArea
        case .bridge:
            self = .bridge
        case .custom:
            self = .userDefined
        @unknown default:
            fatalError("Unknown RoadObjectType value.")
        }
    }

    init(type: MapboxNavigationNative.RoadObjectType, metadata: MapboxNavigationNative.RoadObjectMetadata) {
        switch type {
        case .incident:
            self = .incident(metadata.isIncidentInfo() ? Incident(metadata.getIncidentInfo()) : nil)
        case .tollCollectionPoint:
            self = .tollCollection(metadata.isTollCollectionInfo() ? TollCollection(metadata.getTollCollectionInfo()) : nil)
        case .borderCrossing:
            self = .borderCrossing(metadata.isBorderCrossingInfo() ? BorderCrossing(metadata.getBorderCrossingInfo()) : nil)
        case .tunnel:
            self = .tunnel(metadata.isTunnelInfo() ? Tunnel(metadata.getTunnelInfo()) : nil)
        case .serviceArea:
            self = .serviceArea(metadata.isServiceAreaInfo() ? RestStop(metadata.getServiceAreaInfo()) : nil)
        case .restrictedArea:
            self = .restrictedArea
        case .bridge:
            self = .bridge
        case .custom:
            self = .userDefined
        @unknown default:
            fatalError("Unknown RoadObjectType value.")
        }
    }
}
