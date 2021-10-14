import Foundation
import CoreLocation

/**
 A JSON-compatible representation of a `CLLocation` object for inclusion in an event.
 */
struct EventLocation {
    /// - seealso: `CLLocation.coordinate`
    let coordinate: CLLocationCoordinate2D
    /// - seealso: `CLLocation.altitude`
    let altitude: CLLocationDistance
    
    /// - seealso: `CLLocation.timestamp`
    let timestamp: Date
    
    /// - seealso: `CLLocation.horizontalAccuracy`
    let horizontalAccuracy: CLLocationAccuracy
    /// - seealso: `CLLocation.verticalAccuracy`
    let verticalAccuracy: CLLocationAccuracy
    
    /// - seealso: `CLLocation.courseAccuracy`
    let courseAccuracy: CLLocationDirectionAccuracy?
    /// - seealso: `CLLocation.course`
    let course: CLLocationDirection
    
    /// - seealso: `CLLocation.speed`
    let speed: CLLocationSpeed
    /// - seealso: `CLLocation.speedAccuracy`
    let speedAccuracy: CLLocationSpeedAccuracy
    
    /**
     Initializes an event location consistent with the given location object.
     */
    init(_ location: CLLocation) {
        coordinate = location.coordinate
        altitude = location.altitude
        
        timestamp = location.timestamp
        
        horizontalAccuracy = location.horizontalAccuracy
        verticalAccuracy = location.verticalAccuracy
        
        if #available(iOS 13.4, *) {
            courseAccuracy = location.courseAccuracy
        } else {
            courseAccuracy = nil
        }
        course = location.course
        
        speed = location.speed
        speedAccuracy = location.speedAccuracy
    }
    
    /// Returns a dictionary representation of the location.
    public var dictionaryRepresentation: [String: Any] {
        var locationDictionary: [String: Any] = [
            "lat": coordinate.latitude,
            "lng": coordinate.longitude,
            "altitude": altitude,
            "timestamp": timestamp.ISO8601,
            "horizontalAccuracy": horizontalAccuracy,
            "verticalAccuracy": verticalAccuracy,
            "course": course,
            "speed": speed,
            "speedAccuracy": speedAccuracy,
        ]
        if #available(iOS 13.4, *) {
            locationDictionary["courseAccuracy"] = courseAccuracy
        }
        return locationDictionary
    }
}

extension EventLocation: Encodable {
    enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lng"
        case altitude
        case timestamp
        case horizontalAccuracy
        case verticalAccuracy
        case courseAccuracy
        case course
        case speed
        case speedAccuracy
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(coordinate.latitude, forKey: .latitude)
        try container.encode(coordinate.longitude, forKey: .longitude)
        try container.encode(altitude, forKey: .altitude)
        try container.encode(timestamp.ISO8601, forKey: .timestamp)
        try container.encode(horizontalAccuracy, forKey: .horizontalAccuracy)
        try container.encode(verticalAccuracy, forKey: .verticalAccuracy)
        if #available(iOS 13.4, *) {
            try container.encodeIfPresent(courseAccuracy, forKey: .courseAccuracy)
        }
        try container.encode(course, forKey: .course)
        try container.encode(speed, forKey: .speed)
        try container.encode(speedAccuracy, forKey: .speedAccuracy)
    }
}
