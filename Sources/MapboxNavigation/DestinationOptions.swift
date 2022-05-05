import CoreLocation
import MapboxDirections

// :nodoc:
@_spi(Experimental) public struct DestinationOptions {
    
    // :nodoc:
    public var primaryText: String?
    
    var secondaryText: String?
    
    public private(set) var waypoints: [Waypoint]
    
    public init(coordinates: [CLLocationCoordinate2D]) {
        let waypoints = coordinates.map({ Waypoint(coordinate: $0) })
        self.init(waypoints: waypoints)
    }
    
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
