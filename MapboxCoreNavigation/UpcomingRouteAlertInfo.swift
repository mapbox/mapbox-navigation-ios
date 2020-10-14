import Foundation
import CoreLocation
import MapboxNavigationNative
import MapboxDirections

/**
 `UpcomingRouteAlertInfo` encapsulates information about various incoming events. Common attributes like location, distance to the event, length and other is provided for each POI, while specific meta data is supplied via `alert` property.
 */
public struct UpcomingRouteAlertInfo {
    public enum RouteAlertType {
        case incident(Incident)
        case tunnel(TunnelInfo)
        case borderCrossing(BorderCrossingInfo)
        case tollCollection(TollCollection)
        case serviceArea(RestStop)
    }
    
    /// Alert data with specific info. Contents depend on exact alert type.
    public let alert: RouteAlertType
    
    /// Distance to route alert relative to start of the route, meters.
    public let distance: CLLocationDistance
    /**
     Distance from current position to alert, meters.
     
     This value can be negative if it is a spanned alert and we are somewhere in the middle of it.
     */
    public let distanceToStart: CLLocationDistance
    /**
     Length of the alert info.
     
     This value will be non-null for composite route alerts */
    public let length: CLLocationDistance?
    
    /// Coordinate of route alert beginning point
    public let beginCoordinate: CLLocationCoordinate2D
    /// Coordinate of route alert ending point
    public let endCoordinate: CLLocationCoordinate2D
    
    /// Segment index in corresponding `Route.shape` where this alert begins.
    public let beginSegmentIndex: UInt32
    /// Segment index in corresponding `Route.shape` where this alert ends.
    public let endSegmentIndex: UInt32
    
    init?(_ upcomingAlert: UpcomingRouteAlert) {
        self.distance = upcomingAlert.alert.distance
        self.distanceToStart = upcomingAlert.distanceToStart
        self.length = upcomingAlert.alert.length?.doubleValue
        self.beginCoordinate = upcomingAlert.alert.beginCoordinate
        self.endCoordinate = upcomingAlert.alert.endCoordinate
        self.beginSegmentIndex = upcomingAlert.alert.beginGeometryIndex
        self.endSegmentIndex = upcomingAlert.alert.endGeometryIndex
        
        switch upcomingAlert.alert.type {
        case .kIncident:
            guard let incidentInfo = upcomingAlert.alert.incidentInfo else {
                return nil
            }
            self.alert = .incident(Incident(incidentInfo))
        case .kTunnelEntrance:
            guard let tunnelInfo = upcomingAlert.alert.tunnelInfo else {
                return nil
            }
            self.alert = .tunnel(TunnelInfo(tunnelInfo))
        case .kBorderCrossing:
            guard let adminInfo = upcomingAlert.alert.borderCrossingInfo else {
                return nil
            }
            self.alert = .borderCrossing(BorderCrossingInfo(adminInfo))
        case .kTollCollectionPoint:
            guard let tollInfo = upcomingAlert.alert.tollCollectionInfo else {
                return nil
            }
            self.alert = .tollCollection(TollCollection(tollInfo))
        case .kServiceArea:
            guard let serviceAreaInfo = upcomingAlert.alert.serviceAreaInfo else {
                return nil
            }
            self.alert = .serviceArea(RestStop(serviceAreaInfo))
        default:
            return nil
        }
    }
}
