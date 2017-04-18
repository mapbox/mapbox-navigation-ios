import Foundation
import CoreLocation

protocol SimulatedRouteDelegate : class {
    func simulation(_ locationManager: CLLocationManager, didUpdateLocations locations: [CLLocation])
}

class SimulatedRoute : NSObject {
    
    var speed: CLLocationSpeed = 30
    
    var distanceFilter: CLLocationDistance = 10
    
    var verticalAccuracy: CLLocationAccuracy = 40
    
    var horizontalAccuracy: CLLocationAccuracy = 40
    
    var locations = [CLLocation]()
    
    let locationManager = CLLocationManager()
    
    weak var delegate: SimulatedRouteDelegate?
    
    convenience init(_ polyline: [CLLocationCoordinate2D]) {
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
            let location = CLLocation(coordinate: currentCoordinate,
                                      altitude: 0,
                                      horizontalAccuracy: horizontalAccuracy,
                                      verticalAccuracy: verticalAccuracy,
                                      course: course,
                                      speed: speed,
                                      timestamp: timestamp)
            locations.append(location)
        }
    }
    
    func start() {
        tick()
    }
    
    @objc fileprivate func tick() {
        guard locations.count > 0 else { return }
        let location = locations[0]
        
        delegate?.simulation(locationManager, didUpdateLocations: [location.shifted(to: Date())])
        
        if (locations.count > 1) {
            let nextLocation = locations[1]
            let delay = nextLocation.timestamp.timeIntervalSince(location.timestamp)
            perform(#selector(tick), with: nil, afterDelay: delay)
        } else {
            // Simulation finished
        }
        
        locations.remove(at: 0)
    }
    
    func stop() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(tick), object: nil)
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
}
