import CoreLocation
import MapboxDirections
import MapboxNavigationCore
import MapboxNavigationNative
import Turf

extension CLLocation {
    convenience init(_ location: FixLocation) {
        let timestamp = Date(timeIntervalSince1970: TimeInterval(location.monotonicTimestampNanoseconds) / 1e9)
        self.init(
            coordinate: location.coordinate,
            altitude: location.altitude?.doubleValue ?? 0,
            horizontalAccuracy: location.accuracyHorizontal?.doubleValue ?? -1,
            verticalAccuracy: location.verticalAccuracy?.doubleValue ?? -1,
            course: location.bearing?.doubleValue ?? -1,
            courseAccuracy: location.bearingAccuracy?.doubleValue ?? -1,
            speed: location.speed?.doubleValue ?? -1,
            speedAccuracy: location.speedAccuracy?.doubleValue ?? -1,
            timestamp: timestamp
        )
    }

    var isQualified: Bool {
        return 0...100 ~= horizontalAccuracy
    }

    var isQualifiedForStartingRoute: Bool {
        return 0...20 ~= horizontalAccuracy
    }

    /// Returns a Boolean value indicating whether the receiver is within a given distance of a route step.
    func isWithin(_ maximumDistance: CLLocationDistance, of routeStep: RouteStep) -> Bool {
        guard let shape = routeStep.shape, let closestCoordinate = shape.closestCoordinate(to: coordinate) else {
            return false
        }
        return closestCoordinate.coordinate.distance(to: coordinate) < maximumDistance
    }

    func shifted(to newTimestamp: Date) -> CLLocation {
        return CLLocation(
            coordinate: coordinate,
            altitude: altitude,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            course: course,
            speed: speed,
            timestamp: newTimestamp
        )
    }
}
