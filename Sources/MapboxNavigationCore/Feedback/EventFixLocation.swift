import CoreLocation
import Foundation
import MapboxNavigationNative

struct EventFixLocation {
    let coordinate: CLLocationCoordinate2D
    let altitude: CLLocationDistance?
    let time: Date
    let monotonicTimestampNanoseconds: Int64
    let horizontalAccuracy: CLLocationAccuracy?
    let verticalAccuracy: CLLocationAccuracy?
    let bearingAccuracy: CLLocationDirectionAccuracy?
    let speedAccuracy: CLLocationSpeedAccuracy?
    let bearing: CLLocationDirection?
    let speed: CLLocationSpeed?
    let provider: String?
    let extras: [String: Any]
    let isMock: Bool

    /// Initializes an event location consistent with the given location object.
    init(_ location: FixLocation) {
        self.coordinate = location.coordinate
        self.altitude = location.altitude?.doubleValue
        self.time = location.time
        self.monotonicTimestampNanoseconds = location.monotonicTimestampNanoseconds
        self.speed = location.speed?.doubleValue
        self.bearing = location.bearing?.doubleValue
        self.bearingAccuracy = location.bearingAccuracy?.doubleValue
        self.horizontalAccuracy = location.accuracyHorizontal?.doubleValue
        self.verticalAccuracy = location.verticalAccuracy?.doubleValue
        self.speedAccuracy = location.speedAccuracy?.doubleValue
        self.provider = location.provider
        self.extras = location.extras
        self.isMock = location.isMock
    }
}

extension EventFixLocation: Codable {
    private enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lon"
        case monotonicTimestampNanoseconds
        case time
        case speed
        case bearing
        case altitude
        case accuracyHorizontal
        case provider
        case bearingAccuracy
        case speedAccuracy
        case verticalAccuracy
        case extras
        case isMock
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        let extrasData = try container.decode(Data.self, forKey: .extras)

        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let fixLocation = try FixLocation(
            coordinate: coordinate,
            monotonicTimestampNanoseconds: container.decode(Int64.self, forKey: .monotonicTimestampNanoseconds),
            time: container.decode(Date.self, forKey: .time),
            speed: container.decodeIfPresent(Double.self, forKey: .speed) as NSNumber?,
            bearing: container.decodeIfPresent(Double.self, forKey: .bearing) as NSNumber?,
            altitude: container.decodeIfPresent(Double.self, forKey: .altitude) as NSNumber?,
            accuracyHorizontal: container.decodeIfPresent(Double.self, forKey: .accuracyHorizontal) as NSNumber?,
            provider: container.decodeIfPresent(String.self, forKey: .provider),
            bearingAccuracy: container.decodeIfPresent(Double.self, forKey: .bearingAccuracy) as NSNumber?,
            speedAccuracy: container.decodeIfPresent(Double.self, forKey: .speedAccuracy) as NSNumber?,
            verticalAccuracy: container.decodeIfPresent(Double.self, forKey: .verticalAccuracy) as NSNumber?,
            extras: JSONSerialization.jsonObject(with: extrasData) as? [String: Any] ?? [:],
            isMock: container.decode(Bool.self, forKey: .isMock)
        )
        self.init(fixLocation)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(monotonicTimestampNanoseconds, forKey: .monotonicTimestampNanoseconds)
        try container.encode(time, forKey: .time)
        try container.encode(isMock, forKey: .isMock)
        try container.encodeIfPresent(speed, forKey: .speed)
        try container.encodeIfPresent(bearing, forKey: .bearing)
        try container.encodeIfPresent(altitude, forKey: .altitude)
        try container.encodeIfPresent(provider, forKey: .provider)
        try container.encodeIfPresent(bearingAccuracy, forKey: .bearingAccuracy)
        try container.encodeIfPresent(speedAccuracy, forKey: .speedAccuracy)
        try container.encodeIfPresent(verticalAccuracy, forKey: .verticalAccuracy)
        let extrasData = try JSONSerialization.data(withJSONObject: extras)
        try container.encode(extrasData, forKey: .extras)
    }
}

extension FixLocation {
    convenience init(_ location: EventFixLocation) {
        self.init(
            coordinate: location.coordinate,
            monotonicTimestampNanoseconds: location.monotonicTimestampNanoseconds,
            time: location.time,
            speed: location.speed as NSNumber?,
            bearing: location.bearing as NSNumber?,
            altitude: location.altitude as NSNumber?,
            accuracyHorizontal: location.horizontalAccuracy as NSNumber?,
            provider: location.provider,
            bearingAccuracy: location.bearingAccuracy as NSNumber?,
            speedAccuracy: location.speedAccuracy as NSNumber?,
            verticalAccuracy: location.verticalAccuracy as NSNumber?,
            extras: location.extras,
            isMock: location.isMock
        )
    }
}
