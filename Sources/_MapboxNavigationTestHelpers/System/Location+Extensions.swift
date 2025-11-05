import CoreLocation

extension [CLLocation] {
    func shiftedToPresent() -> [CLLocation] {
        shifted(to: Date())
    }

    func shifted(to timestamp: Date) -> [CLLocation] {
        return enumerated().map { CLLocation(
            coordinate: $0.element.coordinate,
            altitude: $0.element.altitude,
            horizontalAccuracy: $0.element.horizontalAccuracy,
            verticalAccuracy: $0.element.verticalAccuracy,
            course: $0.element.course,
            speed: $0.element.speed,
            timestamp: timestamp + Double($0.offset)
        ) }
    }

    func qualified() -> [CLLocation] {
        return enumerated().map { CLLocation(
            coordinate: $0.element.coordinate,
            altitude: -1,
            horizontalAccuracy: 10,
            verticalAccuracy: -1,
            course: -1,
            speed: 10,
            timestamp: $0.element.timestamp
        ) }
    }
}
