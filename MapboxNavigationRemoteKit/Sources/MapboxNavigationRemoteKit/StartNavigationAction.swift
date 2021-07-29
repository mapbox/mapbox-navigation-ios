import CoreLocation

public struct StartNavigationAction: Codable {
    public init(destination: CLLocationCoordinate2D) {
        self.destination = destination
    }

    public let destination: CLLocationCoordinate2D
}

