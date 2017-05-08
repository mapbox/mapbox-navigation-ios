import Foundation
import CoreLocation

protocol SimulatedRouteDelegate : class {
    func simulation(_ locationManager: CLLocationManager, didUpdateLocations locations: [CLLocation])
}

public class SimulatedLocation: CLLocation {
    public var turnPenalty: Double = 0
}

public class SimulatedRoute : NSObject {
    
    let maximumSpeed: CLLocationSpeed = 30 // ~108 kmh
    let minimumSpeed: CLLocationSpeed = 5 // ~18 kmh
    var speed: CLLocationSpeed = 30
    var distanceFilter: CLLocationDistance = 10
    var verticalAccuracy: CLLocationAccuracy = 40
    var horizontalAccuracy: CLLocationAccuracy = 40
    
    var rawPolyline = [CLLocationCoordinate2D]()
    
    // minimumSpeed will be used when a location have maximumTurnPenalty
    fileprivate let maximumTurnPenalty: CLLocationDirection = 90
    // maximumSpeed will be used when a location have minimumTurnPenalty
    fileprivate let minimumTurnPenalty: CLLocationDirection = 0
    
    public var processedLocations: [CLLocation]!
    
    let locationManager = CLLocationManager()
    
    weak var delegate: SimulatedRouteDelegate?
    
    public convenience init?(along rawPolyline: [CLLocationCoordinate2D]) {
        if rawPolyline.count < 3 {
            print("Not enough coordinates in polyline to simulate")
            return nil
        }
        
        self.init()
        self.rawPolyline = rawPolyline
        
        let turnPenaltyBasedLocations = calculateTurnPenalty(coordinates: rawPolyline)
        let interpolatedLocations = interpolate(locations: turnPenaltyBasedLocations)
        let speedBasedLocations = calculateSpeed(for: interpolatedLocations)
        
        processedLocations = calculateTimestamp(for: speedBasedLocations)
    }
    
    // Calculate time after we estimated speed and distance
    fileprivate func calculateTimestamp(for locations: [SimulatedLocation]) -> [SimulatedLocation] {
        var processedLocations = [SimulatedLocation]()
        
        for (i, location) in locations.enumerated() {
            if i > 0 {
                let distance = location.distance(from: processedLocations.last!)
                let time = distance / location.speed
                let newLocation = location.shifted(to: processedLocations.last!.timestamp.addingTimeInterval(time))
                processedLocations.append(newLocation)
            } else {
                processedLocations.append(location.shifted(to: Date()))
            }
        }
        
        return processedLocations
    }
    
    // Calculate speed based on turn penalty
    fileprivate func calculateSpeed(for locations: [SimulatedLocation]) -> [SimulatedLocation] {
        var processedLocations = [SimulatedLocation]()
        for (i, location) in locations.enumerated() {
            guard i < locations.count else { break }
            let nextLocation = locations[i]
            let reversedTurnPenalty = maximumTurnPenalty - nextLocation.turnPenalty
            let speed = reversedTurnPenalty.scale(inMinimum: minimumTurnPenalty, inMaximum: maximumTurnPenalty, outMinimum: minimumSpeed, outMaximum: maximumSpeed)
            let processedLocation = location.withSpeed(speed)
            processedLocations.append(processedLocation)
        }
        
        return processedLocations
    }
    
    // Inserts new locations to smooth out gaps longer than 1 second.
    fileprivate func interpolate(locations: [SimulatedLocation]) -> [SimulatedLocation] {
        var processedLocations = [SimulatedLocation]()
        for (i, location) in locations.enumerated() {
            processedLocations.append(location)
            
            if i < locations.count-1 {
                let speed = (maximumSpeed - minimumSpeed) / 2
                let nextLocation = locations[i+1]
                let distanceToNext = floor(location.distance(from: nextLocation))
                let timeToTravel = distanceToNext / speed
                
                if timeToTravel > 1 {
                    let newCoordinate = coordinate(at: speed, fromStartOf: [location.coordinate, nextLocation.coordinate])
                    let newLocation = SimulatedLocation(coordinate: newCoordinate!,
                                                        altitude: 0,
                                                        horizontalAccuracy: horizontalAccuracy,
                                                        verticalAccuracy: verticalAccuracy,
                                                        course: wrap(floor(newCoordinate!.direction(to: nextLocation.coordinate)), min: 0, max: 360),
                                                        speed: speed,
                                                        timestamp: Date())
                    processedLocations.append(newLocation)
                }
            }
        }
        
        return processedLocations.count > locations.count ? interpolate(locations: processedLocations) : processedLocations
    }
    
    // Calculate a turn penalty for each coordinate
    fileprivate func calculateTurnPenalty(coordinates: [CLLocationCoordinate2D]) -> [SimulatedLocation] {
        var locations = [SimulatedLocation]()
        let firstCoordinate = coordinates.first!
        let secondCoordinate = coordinates[1]
        let firstLocation = SimulatedLocation(coordinate: coordinates.first!,
                                              altitude: 0,
                                              horizontalAccuracy: 0,
                                              verticalAccuracy: 0,
                                              course: wrap(floor(firstCoordinate.direction(to: secondCoordinate)), min: 0, max: 360),
                                              speed: minimumSpeed,
                                              timestamp: Date())
        locations.append(firstLocation)
        
        for i in 1..<coordinates.count {
            let isLast = (i == coordinates.count-1)
            var course: CLLocationDirection = 0
            var turnPenalty: Double = 0
            
            if isLast == false {
                course = wrap(floor(coordinates[i].direction(to: coordinates[i+1])), min: 0, max: 360)
                turnPenalty = floor(differenceBetweenAngles(coordinates[i-1].direction(to: coordinates[i]), coordinates[i].direction(to: coordinates[i+1])))
            } else {
                course = wrap(floor(coordinates[i-1].direction(to: coordinates[i])), min: 0, max: 360)
            }
            
            let location = SimulatedLocation(coordinate: coordinates[i], altitude: 0, horizontalAccuracy: 0, verticalAccuracy: 0, course: course, speed: minimumSpeed, timestamp: Date())
            location.turnPenalty = max(min(turnPenalty, maximumTurnPenalty), minimumTurnPenalty)
            locations.append(location)
        }
        
        return locations
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
    func scale(inMinimum: Double, inMaximum: Double, outMinimum: Double, outMaximum: Double) -> Double {
        return ((outMaximum - outMinimum) * (self - inMinimum) / (inMaximum - inMinimum)) + outMinimum
    }
}

fileprivate extension SimulatedLocation {
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
