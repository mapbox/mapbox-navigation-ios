import Foundation
import MapboxDirections
import CoreLocation

public class DebugLocation: CLLocation {
    public var debugString = ""
}

public class SimulatedRoute : NSObject {
    
    let maximumSpeed: CLLocationSpeed = 30 // ~108 kmh
    let minimumSpeed: CLLocationSpeed = 2.77 // ~10 kmh
    var speed: CLLocationSpeed = 30
    var distanceFilter: CLLocationDistance = 10
    var verticalAccuracy: CLLocationAccuracy = 40
    var horizontalAccuracy: CLLocationAccuracy = 40
    public var locations = [CLLocation]()
    
    public var coordinates: [CLLocationCoordinate2D] {
        get {
            return locations.map({$0.coordinate})
        }
    }
    
    public convenience init(along polyline: [CLLocationCoordinate2D]) {
        self.init()
        
        let totalDistance = distance(along: polyline)
        let stops = UInt(totalDistance / distanceFilter)
        let distancePerStop = totalDistance / Double(stops)
        
        for index in 0...stops {
            let distance = CLLocationDistance(UInt(distanceFilter) * (index + 1))
            var course: CLLocationDegrees = 0
            let newCoordinate = coordinate(at: distance, fromStartOf: polyline)
            guard let currentCoordinate = newCoordinate else { continue }
            
            if let nextCoordinate = coordinate(at: distance + distanceFilter, fromStartOf: polyline) {
                course = currentCoordinate.direction(to: nextCoordinate)
            }
            
            let timestamp = Date(timeIntervalSince1970: (distancePerStop / speed) * Double(index))
            let location = DebugLocation(coordinate: currentCoordinate,
                                         altitude: 0,
                                         horizontalAccuracy: horizontalAccuracy,
                                         verticalAccuracy: verticalAccuracy,
                                         course: course,
                                         speed: speed,
                                         timestamp: timestamp)
            locations.append(location)
        }
        

        let validLocations = locations[1..<locations.count-2]
        
        var speedAdjustedLocations = [CLLocation]()
        for location in locations {
            guard validLocations.contains(location) else { continue }
            
            let index = locations.index(of: location)!
            let previousLocation = locations[index-1]
            let nextLocation = locations[index+1]
            
            let previousDirection = previousLocation.coordinate.direction(to: location.coordinate)
            let nextDirection = location.coordinate.direction(to: nextLocation.coordinate)
            let angleDiff = differenceBetweenAngles(previousDirection, nextDirection)
            
            let maximumAngle: Double = 45
            let turnPenalty = floor(wrap(max(min(angleDiff, maximumAngle), 0), min: 0.0, max: maximumAngle))
            let coefficient = 1.0 - (turnPenalty / maximumAngle)
            speedAdjustedLocations.append(location.withSpeed(floor(location.speed * coefficient)))
        }
        
        locations = speedAdjustedLocations
    }
}

extension CLLocation {
    func shifted(to shiftedTimestamp: Date) -> CLLocation {
        return CLLocation(coordinate: coordinate,
                          altitude: altitude,
                          horizontalAccuracy: horizontalAccuracy,
                          verticalAccuracy: verticalAccuracy,
                          course: course,
                          speed: speed,
                          timestamp: shiftedTimestamp)
    }
    
    func withSpeed(_ newSpeed: CLLocationSpeed) -> CLLocation {
        return CLLocation(coordinate: coordinate,
                          altitude: altitude,
                          horizontalAccuracy: horizontalAccuracy,
                          verticalAccuracy: verticalAccuracy,
                          course: course,
                          speed: newSpeed,
                          timestamp: timestamp)
    }
    
    public var kilometersPerHour: CLLocationSpeed {
        get {
            return speed * 3.6
        }
    }
}

