import CoreLocation
import MapboxDirections

// :nodoc:
public struct DestinationOptions {
    
    // :nodoc:
    public var primaryText: String?
    
    // :nodoc:
    public var secondaryText: String?
    
    // :nodoc:
    public private(set) var waypoints: [Waypoint]
    
    // :nodoc:
    public init(coordinates: [CLLocationCoordinate2D]) {
        let waypoints = coordinates.map({ Waypoint(coordinate: $0) })
        self.init(waypoints: waypoints)
    }
    
    // :nodoc:
    public init(waypoints: [Waypoint]) {
        self.waypoints = waypoints
        
        if let destinationName = waypoints.last?.name {
            primaryText = destinationName
        }
        
        if let destinationCoordinate = waypoints.last?.coordinate {
            secondaryText = String(format: "(%.5f, %.5f)",
                                   destinationCoordinate.latitude,
                                   destinationCoordinate.longitude)
        }
    }
}
