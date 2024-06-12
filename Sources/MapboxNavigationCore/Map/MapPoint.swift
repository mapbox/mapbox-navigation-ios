import CoreLocation

/// Represents a point that user tapped on the map.
public struct MapPoint: Equatable, Sendable {
    /// Name of the POI that user tapped on. Can be `nil` if there were no POIs nearby.
    /// Developers can adjust ``NavigationMapView/poiClickableAreaSize``
    /// to increase the search area around the touch point.
    public let name: String?
    /// Coordinate of user's tap.
    public let coordinate: CLLocationCoordinate2D

    public init(name: String?, coordinate: CLLocationCoordinate2D) {
        self.name = name
        self.coordinate = coordinate
    }
}
