import CoreLocation
import Solar

extension Solar {
    
    init?(date: Date?, coordinate: CLLocationCoordinate2D) {
        if let date = date {
            self.init(for: date, coordinate: coordinate)
        } else {
            self.init(coordinate: coordinate)
        }
    }
}
