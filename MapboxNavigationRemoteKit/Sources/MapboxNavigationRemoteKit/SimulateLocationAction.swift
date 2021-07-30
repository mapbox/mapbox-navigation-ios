import Foundation
import CoreLocation

public struct SimulateLocationAction: Codable {
    public init(coordinates: [CLLocationCoordinate2D]) {
        self.coordinates = coordinates
    }

    public let coordinates: [CLLocationCoordinate2D]
}
