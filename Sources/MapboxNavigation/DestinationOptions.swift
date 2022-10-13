import CoreLocation
import MapboxDirections

// :nodoc:
public struct DestinationOptions {
    
    // :nodoc:
    public var primaryText: NSAttributedString?
    
    // :nodoc:
    public let waypoints: [Waypoint]
    
    // :nodoc:
    public let coordinates: [CLLocationCoordinate2D]
    
    // :nodoc:
    public init(coordinates: [CLLocationCoordinate2D]) {
        let waypoints = coordinates.map({ Waypoint(coordinate: $0) })
        self.init(waypoints: waypoints)
    }
    
    // :nodoc:
    public init(waypoints: [Waypoint]) {
        self.waypoints = waypoints
        self.coordinates = waypoints.map({ CLLocationCoordinate2D(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) })
        
        if let destinationName = waypoints.last?.name {
            primaryText = NSAttributedString(string: destinationName)
        }
    }
}
