import CoreLocation
import MapboxDirections

// :nodoc:
public struct DestinationOptions {
    
    // :nodoc:
    public var primaryText: String?
    
    // :nodoc:
    public var secondaryText: String?
    
    // :nodoc:
    public private(set) var waypoint: Waypoint
    
    // :nodoc:
    public init(coordinate: CLLocationCoordinate2D) {
        let waypoint = Waypoint(coordinate: coordinate)
        self.init(waypoint: waypoint)
    }
    
    // :nodoc:
    public init(waypoint: Waypoint) {
        self.waypoint = waypoint
        
        if let destinationName = waypoint.name {
            primaryText = destinationName
        }
        
        secondaryText = String(format: "(%.5f, %.5f)",
                               waypoint.coordinate.latitude,
                               waypoint.coordinate.longitude)
    }
}
