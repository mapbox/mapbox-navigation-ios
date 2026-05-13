import CoreLocation
import Foundation
import Turf

/// Represents the type of road camera.
@_spi(ExperimentalMapboxAPI)
public struct CameraType: RawRepresentable, Codable, Equatable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Speed camera that monitors vehicle speed.
    public static let speed = CameraType(rawValue: "SPEED")

    /// Red light camera that monitors traffic signal violations.
    public static let redLight = CameraType(rawValue: "RED_LIGHT")

    /// Combined red light and speed camera.
    public static let redSpeed = CameraType(rawValue: "RED_SPEED")

    /// Average speed zone camera that monitors speed over a distance.
    public static let averageZone = CameraType(rawValue: "AVG_ZONE")

    /// Danger zone camera.
    public static let dangerZone = CameraType(rawValue: "DANGER_ZONE")

    /// Dedicated lane camera that monitors lane usage compliance.
    public static let dedicatedLane = CameraType(rawValue: "DEDICATED_LANE")

    /// Passage camera.
    public static let passage = CameraType(rawValue: "PASSAGE")

    public var description: String {
        return rawValue
    }
}

/// Represents the type of camera sensor location within a zone.
@_spi(ExperimentalMapboxAPI)
public struct SensorType: RawRepresentable, Codable, Equatable, Hashable, Sendable, CustomStringConvertible {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// Sensor at the entry point of a camera zone.
    public static let zoneEntry = SensorType(rawValue: "ZONE_ENTRY")

    /// Sensor in the middle of a camera zone.
    public static let zoneMiddle = SensorType(rawValue: "ZONE_MIDDLE")

    /// Sensor at the exit point of a camera zone.
    public static let zoneExit = SensorType(rawValue: "ZONE_EXIT")

    public var description: String {
        return rawValue
    }
}

/// Road camera representation.
@_spi(ExperimentalMapboxAPI)
public struct RoadCamera: Codable, Equatable, Sendable {
    private enum CodingKeys: String, CodingKey {
        case isActive = "active"
        case latitude
        case longitude
        case sensorType = "sensor_type"
        case sensorUUID = "sensor_uuid"
        case cameraType = "camera_type"
        case cameraUUID = "camera_uuid"
        case speed
        case distanceAlongLeg = "distance_along_leg"
    }

    /// Indicates whether the camera is currently active.
    public let isActive: Bool

    /// The latitude coordinate of the camera location.
    let latitude: Turf.LocationDegrees

    /// The longitude coordinate of the camera location.
    let longitude: Turf.LocationDegrees

    /// The type of sensor location within a camera zone.
    public let sensorType: SensorType

    /// The unique identifier for the sensor.
    public let sensorUUID: String

    /// The type of road camera.
    public let cameraType: CameraType

    /// The unique identifier for the camera.
    public let cameraUUID: String

    /// The speed limit enforced by the camera, measured in meters per second.
    public let speed: LocationSpeed?

    /// The distance along the route leg where the camera is located, measured in meters.
    public let distanceAlongLeg: Turf.LocationDistance

    /// The coordinate of the camera location.
    public var coordinate: LocationCoordinate2D {
        LocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
