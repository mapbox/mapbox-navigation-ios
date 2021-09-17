import Foundation
import MapboxDirections
import MapboxNavigationNative

extension RoadObject {
    
    /**
     Type of the road object.
     */
    public enum Kind {
        
        /**
         An alert providing information about incidents on a route. Incidents can include *congestion*,
         *massTransit*, and more (see `Kind` for the full list of incident types).
         */
        case incident(Incident?)
        
        /**
         An alert describing a point along the route where a toll may be collected. Note that this does
         not describe the entire toll road, rather it describes a booth or electronic gate where a toll
         is typically charged. See `CollectionType`.
         */
        case tollCollection(TollCollection?)
        
        /**
         An alert describing a country border crossing along the route. The alert triggers at the point
         where the administrative boundary changes from one country to another. Two-letter and
         three-letter ISO 3166-1 country codes are provided for the exiting country and the entering
         country. See `BorderCrossingInfo`.
         */
        case borderCrossing(BorderCrossing?)
        
        /**
         An alert describing a section of the route that continues through a tunnel. The alert begins at
         the entrance of the tunnel and ends at the exit of the tunnel. For named tunnels, the tunnel name
         is provided as part of `Tunnel.name`.
         */
        case tunnel(Tunnel?)
        
        /**
         An alert about a rest area or service area accessible from the route. The alert marks the point
         along the route where a driver can choose to pull off to access a rest stop. See `StopType`.
         */
        case serviceArea(RestStop?)
        
        /**
         An alert about a segment of a route that includes a restriction. Restricted roads can include
         private access roads or gated areas that can be accessed but are not open to vehicles passing
         through.
         */
        case restrictedArea
        
        /**
         An alert about a segment of a route that includes a bridge.
         */
        case bridge
        
        /**
         Reserved for future use.
         */
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
                fatalError("Unknown MapboxNavigationNative.RoadObjectType value.")
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
                fatalError("Unknown MapboxNavigationNative.RoadObjectType value.")
            }
        }
    }
}
