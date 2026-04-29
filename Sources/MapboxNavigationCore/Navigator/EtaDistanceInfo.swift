import CoreLocation
import Foundation

public struct EtaDistanceInfo: Equatable, Sendable {
    public var distance: CLLocationDistance
    public var travelTime: TimeInterval?

    public init(distance: CLLocationDistance, travelTime: TimeInterval?) {
        self.distance = distance
        self.travelTime = travelTime
    }
}
