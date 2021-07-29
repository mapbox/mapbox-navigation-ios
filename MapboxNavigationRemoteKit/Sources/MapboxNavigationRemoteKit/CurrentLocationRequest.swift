import Foundation
import CoreLocation

public struct CurrentLocationRequest: Codable {
    public init() {}
}

public struct CurrentLocationResponse: Codable {
    public init(location: CLLocationCoordinate2D) {
        self.location = location
    }

    public let location: CLLocationCoordinate2D
}
