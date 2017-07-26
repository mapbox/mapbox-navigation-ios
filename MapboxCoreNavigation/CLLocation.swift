import CoreLocation

extension Array {
    
    /**
     Initializes a [CLLocation] from a JSON string at a given filePath.
     
     The JSON string must conform to the following structure:
     [{
         "latitude": 37.8,          // latitude or lat
         "longitude": -122.4        // longitude, lng, or lon
         "verticalAccuracy": 4,
         "speed": 21.0
         "horizontalAccuracy": 5,
         "course": 0.48
         "timestamp": 1497475447,   // timestamp as unix timestamp or ISO8601Date
         "altitude": 57.26
     }]
     
     - parameter filePath: The file’s path.
     - returns: A [CLLocation].
     */
    public static func locations(from filePath: String) -> [CLLocation]! {
        let url = URL(fileURLWithPath: filePath)
        
        do {
            let data = try Data(contentsOf: url)
            let serialized = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [[String: Any]]
            
            var locations = [CLLocation]()
            for dict in serialized {
                locations.append(CLLocation(dictionary: dict))
            }
            
            return locations.sorted(by: { $0.timestamp < $1.timestamp })
            
        } catch {
            return []
        }
    }
}

extension DateFormatter {
    fileprivate class var ISO8601: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }
}

extension String {
    var ISO8601Date: Date? {
        return DateFormatter.ISO8601.date(from: self)
    }
}

extension CLLocation {
    
    var dictionaryRepresentation: [String: Any] {
        var locationDictionary: [String: Any] = [:]
        locationDictionary["lat"] = coordinate.latitude
        locationDictionary["lng"] = coordinate.longitude
        locationDictionary["altitude"] = altitude
        locationDictionary["timestamp"] = timestamp.ISO8601
        locationDictionary["horizontalAccuracy"] = horizontalAccuracy
        locationDictionary["verticalAccuracy"] = verticalAccuracy
        locationDictionary["course"] = course
        locationDictionary["speed"] = speed
        return locationDictionary
    }
    
    convenience init(dictionary: [String:Any]) {
        let latitude = dictionary["latitude"] as? CLLocationDegrees ?? dictionary["lat"] as? CLLocationDegrees ?? 0
        let longitude = dictionary["longitude"] as? CLLocationDegrees ?? dictionary["lon"] as? CLLocationDegrees ?? dictionary["lng"] as? CLLocationDegrees ?? 0
        let altitude = dictionary["altitude"] as! CLLocationDistance
        
        let horizontalAccuracy = dictionary["horizontalAccuracy"] as! CLLocationAccuracy
        let verticalAccuracy = dictionary["verticalAccuracy"] as! CLLocationAccuracy
        
        let speed = dictionary["speed"] as! CLLocationSpeed
        let course = dictionary["course"] as! CLLocationDirection
        
        var date: Date?
        
        // Parse timestamp as unix timestamp or ISO8601Date
        if let timestamp = dictionary["timestamp"] as? TimeInterval {
            date = Date(timeIntervalSince1970: timestamp)
        } else if let timestamp = dictionary["timestamp"] as? String {
            date = timestamp.ISO8601Date
        }
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        self.init(coordinate: coordinate,
                  altitude: altitude,
                  horizontalAccuracy: horizontalAccuracy,
                  verticalAccuracy: verticalAccuracy,
                  course: course,
                  speed: speed,
                  timestamp: date!)
    }
}
