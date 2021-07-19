import Foundation
import CoreLocation
import Turf

/// Codable CLLocationCoordinate2D conforming to the GeoJSON standard rfc7946 ([longitude, latitude])
extension CLLocationCoordinate2D: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(longitude)
        try container.encode(latitude)
    }
    
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let longitude = try container.decode(CLLocationDegrees.self)
        let latitude = try container.decode(CLLocationDegrees.self)
        self.init(latitude: latitude, longitude: longitude)
    }
}

enum DecodingError: Error {
    case missingData
}

/// A Codable Location with support for the following format:
/**
 "latitude/lat": Double,
 "longitude/lon/lng": Double,
 "coordinate": [Double, Double] (GeoJSON compatible)
 "horizontalAccuracy": Double,
 "course": Double,
 "verticalAccuracy": Double,
 "speed": Double,
 "altitude": Double,
 "timestamp": (Int or String as ISO8601)
 */
public struct Location: Codable {
    enum CodingKeys: String, CodingKey {
        // coordinate can be represented as GeoJSON [lon, lat]
        case coordinate
        // and/or "latitude/lat": 0.0
        case latitude, lat
        // and/or "longitude/lng/lon": 0.0
        case longitude, lng, lon
        case altitude
        case horizontalAccuracy
        case verticalAccuracy
        case course
        case speed
        case timestamp
    }
    
    let coordinate: CLLocationCoordinate2D
    let altitude: CLLocationDistance
    let horizontalAccuracy: CLLocationAccuracy
    let verticalAccuracy: CLLocationAccuracy
    let course: CLLocationDirection
    let speed: CLLocationSpeed
    let timestamp: Date
    
    public init(_ location: CLLocation) {
        self.coordinate = location.coordinate
        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
        self.verticalAccuracy = location.verticalAccuracy
        self.course = location.course
        self.speed = location.speed
        self.timestamp = location.timestamp
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if let coordinate = try? container.decode(CLLocationCoordinate2D.self, forKey: .coordinate) {
            self.coordinate = coordinate
        } else {
            let _latitude = try? container.decode(CLLocationDegrees.self, forKey: .latitude)
            let _lat = try? container.decode(CLLocationDegrees.self, forKey: .lat)
            let _longitude = try? container.decode(CLLocationDegrees.self, forKey: .longitude)
            let _lon = try? container.decode(CLLocationDegrees.self, forKey: .lon)
            let _lng = try? container.decode(CLLocationDegrees.self, forKey: .lng)
            
            if let latitute = _latitude ?? _lat, let longitude = _longitude ?? _lon ?? _lng {
                self.coordinate = CLLocationCoordinate2D(latitude: latitute, longitude: longitude)
            } else {
                throw DecodingError.missingData
            }
        }
        
        self.altitude = try container.decode(CLLocationDistance.self, forKey: .altitude)
        self.horizontalAccuracy = try container.decode(CLLocationAccuracy.self, forKey: .horizontalAccuracy)
        self.verticalAccuracy = try container.decode(CLLocationAccuracy.self, forKey: .verticalAccuracy)
        self.course = try container.decode(CLLocationDirection.self, forKey: .course)
        self.speed = try container.decode(CLLocationSpeed.self, forKey: .speed)
        
        if let timestamp = try? container.decode(TimeInterval.self, forKey: .timestamp) {
            self.timestamp = Date(timeIntervalSince1970: timestamp)
        } else if let timestamp = try? container.decode(String.self, forKey: .timestamp) {
            self.timestamp = timestamp.ISO8601Date!
        } else {
            throw DecodingError.missingData
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(coordinate.latitude, forKey: .lat)
        try container.encode(coordinate.longitude, forKey: .lng)
        try container.encode(altitude, forKey: .altitude)
        try container.encode(horizontalAccuracy, forKey: .horizontalAccuracy)
        try container.encode(verticalAccuracy, forKey: .verticalAccuracy)
        try container.encode(course, forKey: .course)
        try container.encode(speed, forKey: .speed)
        try container.encode(timestamp.ISO8601, forKey: .timestamp)
    }
}

extension CLLocation {
    public convenience init(_ location: Location) {
        self.init(coordinate: location.coordinate, altitude: location.altitude, horizontalAccuracy: location.horizontalAccuracy, verticalAccuracy: location.verticalAccuracy, course: location.course, speed: location.speed, timestamp: location.timestamp)
    }
}

extension String {
    var ISO8601Date: Date? {
        return Date.ISO8601Formatter.date(from: self)
    }
}

extension Date {
    var ISO8601: String {
        return Date.ISO8601Formatter.string(from: self)
    }
    
    static let ISO8601Formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

extension Array where Element == CLLocation {
    // Shifts the [CLLocation]’s first location to now and offsets the remaining locations by one second after the prior.
    public func shiftedToPresent() -> [CLLocation] {
        return shifted(to: Date())
    }
    
    // Shifts the [CLLocation]’s first location to the given timestamp and offsets the remaining locations by one second after the prior.
    public func shifted(to timestamp: Date) -> [CLLocation] {
        return enumerated().map { CLLocation(coordinate: $0.element.coordinate,
                                             altitude: $0.element.altitude,
                                             horizontalAccuracy: $0.element.horizontalAccuracy,
                                             verticalAccuracy: $0.element.verticalAccuracy,
                                             course: $0.element.course,
                                             speed: $0.element.speed,
                                             timestamp: timestamp + $0.offset) }
    }
    
    // Returns a [CLLocation] with course and accuracies qualified for navigation native.
    public func qualified() -> [CLLocation] {
        return enumerated().map { CLLocation(coordinate: $0.element.coordinate,
                                             altitude: -1,
                                             horizontalAccuracy: 10,
                                             verticalAccuracy: -1,
                                             course: -1,
                                             speed: 10,
                                             timestamp: $0.element.timestamp) }
    }
    
    public static func locations(from filePath: String) -> [CLLocation] {
        let data = Fixture.JSONFromFileNamed(name: filePath)
        let locations = try! JSONDecoder().decode([Location].self, from: data)
        
        return locations.map { CLLocation($0) }
    }
}
