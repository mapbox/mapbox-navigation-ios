import CoreLocation


extension CLLocation {
    
    var isQualified: Bool {
        #if (arch(i386) || arch(x86_64)) && (os(iOS) || os(watchOS) || os(tvOS))
            return true
        #else
            return
                0...100 ~= horizontalAccuracy &&
                0...30 ~= verticalAccuracy &&
                speed >= 0
        #endif
    }
    
    /// Returns a dictionary representation of the location.
    public var dictionaryRepresentation: [String: Any] {
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
    
    /**
     Intializes a CLLocation from a dictionary.
     
     - parameter dictionary: A dictionary representation of the location.
     */
    public convenience init(dictionary: [String:Any]) {
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
    
    /**
     Returns a `CLLocation` infront of the provided location given the interval
     with the current speed taken into account.
    */
    public func advanced(by interval: TimeInterval) -> CLLocation {
        let metersAhead = speed * interval
        let locationInfrontOfUser = coordinate.coordinate(at: metersAhead, facing: course)
        return CLLocation(coordinate: locationInfrontOfUser.coordinate(at: metersAhead, facing: course),
                          altitude: altitude,
                          horizontalAccuracy: horizontalAccuracy,
                          verticalAccuracy: verticalAccuracy,
                          course: course,
                          speed: speed,
                          timestamp: timestamp.addingTimeInterval(interval))
    }
    
    /**
     Returns the maximum reroute radius
     */
    public static func radiusForRerouting(with horizontalAccuracy: CLLocationAccuracy) -> CLLocationDistance {
        return max(RouteControllerMaximumDistanceBeforeRecalculating, horizontalAccuracy + RouteControllerUserLocationSnappingDistance)
    }
    
    /**
     Returns the maximum reroute radius
     */
    public var rerouteRadius: CLLocationDistance {
        return CLLocation.radiusForRerouting(with: horizontalAccuracy)
    }
}
