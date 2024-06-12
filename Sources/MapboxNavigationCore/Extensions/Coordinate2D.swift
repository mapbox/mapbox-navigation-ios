import CoreLocation
import Foundation
import MapboxCommon

extension Coordinate2D {
    convenience init(_ coordinate: CLLocationCoordinate2D) {
        self.init(value: .init(latitude: coordinate.latitude, longitude: coordinate.longitude))
    }
}

extension CLLocation {
    convenience init(_ coordinate: Coordinate2D) {
        self.init(latitude: coordinate.value.latitude, longitude: coordinate.value.longitude)
    }
}
