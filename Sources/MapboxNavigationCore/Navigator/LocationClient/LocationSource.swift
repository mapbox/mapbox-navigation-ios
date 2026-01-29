import CoreLocation
import Foundation

public enum LocationSource: Equatable, @unchecked Sendable {
    case simulation(initialLocation: CLLocation? = nil, speedMultiplier: Double = 1)
    case live
    case custom(LocationClient)
}
