import Foundation
import MapboxDirections
import MapboxNavigationNative

public enum EHorizonObjectMetadata {
    /**
     Incident.
     
     Objects provided by Mapbox have additional information about the incident.
     */
    case incident(Incident?)
    
    /**
     Tunnel entrance.
     
     Objects provided by Mapbox have additional information about the tunnel.
     */
    case tunnelEntrance(Tunnel?)
    
    /**
     Tunnel exit.
     
     Objects provided by Mapbox have additional information about the tunnel.
     */
    case tunnelExit(Tunnel?)
    
    /**
     Border crossing.
     
     Objects provided by Mapbox have additional information about the border crossing.
     */
    case borderCrossing(BorderCrossing?)
    
    /**
     Toll collection point.
     
     Objects provided by Mapbox have additional information about the toll collection point.
     */
    case tollCollection(TollCollection?)

    /**
     Service area, also known as a rest stop.
     
     Objects provided by Mapbox have additional information about the service area.
     */
    case serviceArea(RestStop?)
    
    /// Restricted area entrance
    case restrictedAreaEntrance

    /// Restricted area exit
    case restrictedAreaExit
    
    /// Bridge entrance
    case bridgeEntrance

    /// Bridge exit
    case bridgeExit
    
    /// Object was added by the application using the `RoadObjectsStore.addCustomRoadObject(for:location:)` method.
    case userDefined

    init(_ native: RoadObjectMetadata) {
        switch native.type {
        case .incident:
            self = .incident(native.incident != nil ? Incident(native.incident!) : nil)
        case .tunnelEntrance:
            self = .tunnelEntrance(native.tunnelInfo != nil ? Tunnel(native.tunnelInfo!) : nil)
        case .tunnelExit:
            self = .tunnelExit(native.tunnelInfo != nil ? Tunnel(native.tunnelInfo!) : nil)
        case .borderCrossing:
            self = .borderCrossing(native.borderCrossingInfo != nil ? BorderCrossing(native.borderCrossingInfo!) : nil)
        case .tollCollectionPoint:
            self = .tollCollection(native.tollCollectionInfo != nil ? TollCollection(native.tollCollectionInfo!) : nil)
        case .serviceArea:
            self = .serviceArea(native.serviceAreaInfo != nil ? RestStop.init(native.serviceAreaInfo!) : nil)
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
