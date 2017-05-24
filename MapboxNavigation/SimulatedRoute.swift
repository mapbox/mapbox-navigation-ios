import Foundation
import CoreLocation

fileprivate let maximumSpeed: CLLocationSpeed = 30 // ~108 kmh
fileprivate let minimumSpeed: CLLocationSpeed = 5 // ~18 kmh
fileprivate var distanceFilter: CLLocationDistance = 10
fileprivate var verticalAccuracy: CLLocationAccuracy = 40
fileprivate var horizontalAccuracy: CLLocationAccuracy = 40
// minimumSpeed will be used when a location have maximumTurnPenalty
fileprivate let maximumTurnPenalty: CLLocationDirection = 90
// maximumSpeed will be used when a location have minimumTurnPenalty
fileprivate let minimumTurnPenalty: CLLocationDirection = 0

protocol SimulatedRouteDelegate : class {
    func simulation(_ locationManager: CLLocationManager, didUpdateLocations locations: [CLLocation])
}

class SimulatedLocation: CLLocation {
    var turnPenalty: Double = 0
}

extension CLLocationCoordinate2D {
    static func !=(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude != rhs.latitude || lhs.longitude != rhs.longitude
    }
}

class SimulatedRoute : NSObject {
    var polyline = [CLLocationCoordinate2D]()
    
    var processedLocations: [CLLocation]!
    let locationManager = CLLocationManager()
    weak var delegate: SimulatedRouteDelegate?
    
    convenience init?(along polyline: [CLLocationCoordinate2D]) {
        guard polyline.count > 2 else { return nil }
        
        self.init()
        self.polyline = polyline
        
        processedLocations = polyline
            .simulatedLocationsWithTurnPenalties()
            .interpolated()
            .withSpeeds()
            .withShiftedTimestamps()
    }
    
    func start() {
        tick()
    }
    
    @objc fileprivate func tick() {
        guard processedLocations.count > 0 else { return }
        let location = processedLocations[0] as! SimulatedLocation
        delegate?.simulation(locationManager, didUpdateLocations: [location.shifted(to: Date())])
        
        if (processedLocations.count > 1) {
            let nextLocation = processedLocations[1]
            let delay = nextLocation.timestamp.timeIntervalSince(location.timestamp)
            perform(#selector(tick), with: nil, afterDelay: delay)
        } else {
            // Simulation finished
        }
        
        processedLocations.remove(at: 0)
    }
    
    func stop() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(tick), object: nil)
    }
}

fileprivate extension Double {
    func scale(minimumIn: Double, maximumIn: Double, minimumOut: Double, maximumOut: Double) -> Double {
        return ((maximumOut - minimumOut) * (self - minimumIn) / (maximumIn - minimumIn)) + minimumOut
    }
}

fileprivate extension Array where Element == CLLocationCoordinate2D {
    
    // Calculate turn penalty for each coordinate.
    fileprivate func simulatedLocationsWithTurnPenalties() -> [SimulatedLocation] {
        var locations = [SimulatedLocation]()
        
        for (coordinate, nextCoordinate) in zip(prefix(upTo: endIndex - 1), suffix(from: 1)) {
            let currentCoordinate = locations.isEmpty ? first! : coordinate
            let course: CLLocationDirection = wrap(floor(coordinate.direction(to: nextCoordinate)), min: 0, max: 360)
            let turnPenalty: Double = floor(differenceBetweenAngles(currentCoordinate.direction(to: coordinate), coordinate.direction(to: nextCoordinate)))
            let location = SimulatedLocation(coordinate: coordinate,
                                             altitude: 0,
                                             horizontalAccuracy: horizontalAccuracy,
                                             verticalAccuracy: verticalAccuracy,
                                             course: course,
                                             speed: minimumSpeed,
                                             timestamp: Date())
            location.turnPenalty = Swift.max(Swift.min(turnPenalty, maximumTurnPenalty), minimumTurnPenalty)
            locations.append(location)
        }
        
        locations.append(SimulatedLocation(coordinate: last!,
                                           altitude: 0,
                                           horizontalAccuracy: horizontalAccuracy,
                                           verticalAccuracy: verticalAccuracy,
                                           course: locations.last!.course,
                                           speed: minimumSpeed,
                                           timestamp: Date()))
        
        return locations
    }
}

fileprivate extension Array where Element == SimulatedLocation {
    
    // Recursively inserts new locations to smooth out gaps longer than 1 second.
    fileprivate func interpolated() -> [SimulatedLocation] {
        var processedLocations = [SimulatedLocation]()
        
        for (location, nextLocation) in zip(prefix(upTo: endIndex - 1), suffix(from: 1)) {
            processedLocations.append(location)
            
            let speed = (maximumSpeed - minimumSpeed) / 2
            let distance = floor(location.distance(from: nextLocation))
            let timeToTravel: TimeInterval = distance / speed
            
            if timeToTravel > 1 {
                let newCoordinate = coordinate(at: speed, fromStartOf: [location.coordinate, nextLocation.coordinate])
                let newLocation = SimulatedLocation(coordinate: newCoordinate!,
                                                    altitude: location.altitude,
                                                    horizontalAccuracy: horizontalAccuracy,
                                                    verticalAccuracy: verticalAccuracy,
                                                    course: wrap(floor(newCoordinate!.direction(to: nextLocation.coordinate)), min: 0, max: 360),
                                                    speed: speed,
                                                    timestamp: Date())
                processedLocations.append(newLocation)
            }
        }
        
        processedLocations.append(last!)
        
        return processedLocations.count > count ? processedLocations.interpolated() : processedLocations
    }
    
    fileprivate func withShiftedTimestamps() -> [SimulatedLocation] {
        var processedLocations = [SimulatedLocation]()
        
        for location in self {
            if location == first {
                processedLocations.append(location.shifted(to: Date()))
            } else {
                let distance = location.distance(from: processedLocations.last!)
                let shiftedLocation = location.shifted(to: processedLocations.last!.timestamp.addingTimeInterval(distance / location.speed))
                processedLocations.append(shiftedLocation)
            }
        }
        
        return processedLocations
    }
    
    // Calculate speed based on turn penalty.
    fileprivate func withSpeeds() -> [SimulatedLocation] {
        return map({$0.withPenalizedSpeed})
    }
}

fileprivate extension SimulatedLocation {
    
    var withPenalizedSpeed: SimulatedLocation {
        let reversedTurnPenalty = maximumTurnPenalty - turnPenalty
        let speed = reversedTurnPenalty.scale(minimumIn: minimumTurnPenalty, maximumIn: maximumTurnPenalty, minimumOut: minimumSpeed, maximumOut: maximumSpeed)
        return withSpeed(speed)
    }
    
    func shifted(to shiftedTimestamp: Date) -> SimulatedLocation {
        let location = SimulatedLocation(coordinate: coordinate,
                                         altitude: altitude,
                                         horizontalAccuracy: horizontalAccuracy,
                                         verticalAccuracy: verticalAccuracy,
                                         course: course,
                                         speed: speed,
                                         timestamp: shiftedTimestamp)
        location.turnPenalty = turnPenalty
        return location
    }
    
    func withSpeed(_ newSpeed: CLLocationSpeed) -> SimulatedLocation {
        let location = SimulatedLocation(coordinate: coordinate,
                                         altitude: altitude,
                                         horizontalAccuracy: horizontalAccuracy,
                                         verticalAccuracy: verticalAccuracy,
                                         course: course,
                                         speed: newSpeed,
                                         timestamp: timestamp)
        location.turnPenalty = turnPenalty
        return location
    }
}
