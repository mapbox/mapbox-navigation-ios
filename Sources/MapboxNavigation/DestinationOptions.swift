import CoreLocation
import MapboxDirections

/**
 Customization options for the destination(s) preview using `DestinationPreviewViewController` banner.
 */
public struct DestinationOptions {
    
    /**
     Primary text that is going to be shown in `DestinationPreviewViewController`. In case if
     last waypoint in `DestinationOptions.waypoints` contains non-nil value `Waypoint.name` it'll be
     used.
     */
    public var primaryText: NSAttributedString?
    
    /**
     Array of waypoints which are presented.
     */
    public let waypoints: [Waypoint]
    
    /**
     Array of coordinates which are presented.
     */
    public let coordinates: [CLLocationCoordinate2D]
    
    /**
     Initializes a `DestinationOptions` struct.
     
     - paramater coordinates: List of coordinates which are presented.
     */
    public init(coordinates: [CLLocationCoordinate2D]) {
        let waypoints = coordinates.map({ Waypoint(coordinate: $0) })
        self.init(waypoints: waypoints)
    }
    
    /**
     Initializes a `DestinationOptions` struct.
     
     - paramater waypoints: List of waypoints which are presented.
     */
    public init(waypoints: [Waypoint]) {
        self.waypoints = waypoints
        self.coordinates = waypoints.map({ CLLocationCoordinate2D(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) })
        
        if let destinationName = waypoints.last?.name {
            primaryText = NSAttributedString(string: destinationName)
        }
    }
}
