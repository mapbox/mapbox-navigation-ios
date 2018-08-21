import Foundation
import MapboxDirections
#if canImport(CarPlay)
import CarPlay

@available(iOS 12.0, *)
extension Route {
    /**
     Creates a `CPTravelEstimates` from a given route.
     */
    @available(iOS 12.0, *)
    public var travelEstimates: CPTravelEstimates {
        let distanceMeasurement = Measurement(value: distance, unit: UnitLength.meters)
        return CPTravelEstimates(distanceRemaining: distanceMeasurement, timeRemaining: expectedTravelTime)
    }
}
#endif
