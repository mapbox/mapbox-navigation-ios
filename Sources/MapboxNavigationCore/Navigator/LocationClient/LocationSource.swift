import CoreLocation
import Foundation

public enum LocationSource: Equatable, @unchecked Sendable {
    case simulation(initialLocation: CLLocation? = nil)
    case live
    case custom(LocationClient)
}
