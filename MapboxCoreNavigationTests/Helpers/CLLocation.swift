import CoreLocation

extension Array {
    
    /**
     Initializes a [CLLocation] from a JSON string at a given filePath.
     
     The JSON string must conform to the following structure:
     [{
         "verticalAccuracy": 4,
         "speed": 21.0
         "longitude": -122.4
         "horizontalAccuracy": 5,
         "course": 0.48
         "latitude": 37.8
         "timestamp": 1497475447,
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

extension CLLocation {
    
    fileprivate convenience init(dictionary: [String:Any]) {
        let latitude = dictionary["latitude"] as! CLLocationDegrees
        let longitude = dictionary["longitude"] as! CLLocationDegrees
        let altitude = dictionary["altitude"] as! CLLocationDistance
        
        let horizontalAccuracy = dictionary["horizontalAccuracy"] as! CLLocationAccuracy
        let verticalAccuracy = dictionary["verticalAccuracy"] as! CLLocationAccuracy
        
        let speed = dictionary["speed"] as! CLLocationSpeed
        let course = dictionary["course"] as! CLLocationDirection
        let unixTimestamp = dictionary["timestamp"] as! TimeInterval
        let timestamp = Date(timeIntervalSince1970: unixTimestamp)
        
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        self.init(coordinate: coordinate,
                  altitude: altitude,
                  horizontalAccuracy: horizontalAccuracy,
                  verticalAccuracy: verticalAccuracy,
                  course: course,
                  speed: speed,
                  timestamp: timestamp)
    }
}
