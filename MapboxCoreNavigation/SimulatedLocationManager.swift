import Foundation
import MapboxDirections

fileprivate let maximumSpeed: CLLocationSpeed = 30 // ~108 kmh
fileprivate let minimumSpeed: CLLocationSpeed = 6 // ~21 kmh
fileprivate var distanceFilter: CLLocationDistance = 10
fileprivate var verticalAccuracy: CLLocationAccuracy = 40
fileprivate var horizontalAccuracy: CLLocationAccuracy = 40
// minimumSpeed will be used when a location have maximumTurnPenalty
fileprivate let maximumTurnPenalty: CLLocationDirection = 90
// maximumSpeed will be used when a location have minimumTurnPenalty
fileprivate let minimumTurnPenalty: CLLocationDirection = 0
// Go maximum speed if distance to nearest coordinate is >= `safeDistance`
fileprivate let safeDistance: CLLocationDistance = 50

fileprivate class SimulatedLocation: CLLocation {
    var turnPenalty: Double = 0
    
    override var description: String {
        return "\(super.description) \(turnPenalty)"
    }
}

/**
 The `SimulatedLocationManager` class simulates location updates along a given route.
 
 The route will be replaced upon a `RouteControllerDidReroute` notification.
 */
public class SimulatedLocationManager: NavigationLocationManager {
    fileprivate var currentDistance: CLLocationDistance = 0
    fileprivate var currentLocation = CLLocation()
    fileprivate var currentSpeed: CLLocationSpeed = 30
    
    fileprivate var locations: [SimulatedLocation]!
    fileprivate var routeLine = [CLLocationCoordinate2D]()
    
    var route: Route? {
        didSet {
            reset()
        }
    }
    
    /**
     Initalizes a new `SimulatedLocationManager` with the given route.
     
     - parameter route: The initial route.
     - returns: A `SimulatedLocationManager`
     */
    public init(route: Route) {
        super.init()
        self.route = route
        reset()
        NotificationCenter.default.addObserver(self, selector: #selector(didReroute(notification:)), name: RouteControllerDidReroute, object: nil)
    }
    
    private func reset() {
        if let coordinates = route?.coordinates {
            routeLine = coordinates
            locations = coordinates.simulatedLocationsWithTurnPenalties()
            
            currentDistance = 0
            currentSpeed = 30
            startUpdatingLocation()
        }
    }
    
    @objc private func didReroute(notification: Notification) {
        guard let routeController = notification.object as? RouteController else {
            return
        }
        
        route = routeController.routeProgress.route
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: RouteControllerDidReroute, object: nil)
    }
    
    override public func startUpdatingLocation() {
        tick()
    }
    
    override public func stopUpdatingLocation() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(tick), object: nil)
    }
    
    @objc fileprivate func tick() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(tick), object: nil)
        
        guard let newCoordinate = coordinate(at: currentDistance, fromStartOf: routeLine) else {
            return
        }
        
        // Closest coordinate ahead
        guard let lookAheadCoordinate = coordinate(at: currentDistance + 10, fromStartOf: routeLine) else { return }
        guard let closestCoordinate = closestCoordinate(on: routeLine, to: newCoordinate) else { return }
        
        let closestLocation = locations[closestCoordinate.index]
        let distanceToClosest = closestLocation.distance(from: CLLocation(newCoordinate))
        
        let distance = min(max(distanceToClosest, 10), safeDistance)
        let coordinatesNearby = polyline(along: routeLine, within: 100, of: newCoordinate)
        
        // More than 10 nearby coordinates indicates that we are in a roundabout or similar complex shape.
        if coordinatesNearby.count >= 10
        {
            currentSpeed = minimumSpeed
        }
        // Maximum speed if we are a safe distance from the closest coordinate
        else if distance >= safeDistance
        {
            currentSpeed = maximumSpeed
        }
        // Base speed on previous or upcoming turn penalty
        else {
            let reversedTurnPenalty = maximumTurnPenalty - closestLocation.turnPenalty
            currentSpeed = reversedTurnPenalty.scale(minimumIn: minimumTurnPenalty, maximumIn: maximumTurnPenalty, minimumOut: minimumSpeed, maximumOut: maximumSpeed)
        }
        
        currentLocation = CLLocation(coordinate: newCoordinate,
                                     altitude: 0,
                                     horizontalAccuracy: horizontalAccuracy,
                                     verticalAccuracy: verticalAccuracy,
                                     course: wrap(floor(newCoordinate.direction(to: lookAheadCoordinate)), min: 0, max: 360),
                                     speed: currentSpeed,
                                     timestamp: Date())
        
        delegate?.locationManager?(self, didUpdateLocations: [currentLocation])
        currentDistance += currentSpeed
        perform(#selector(tick), with: nil, afterDelay: 0.95)
    }
}

extension Double {
    fileprivate func scale(minimumIn: Double, maximumIn: Double, minimumOut: Double, maximumOut: Double) -> Double {
        return ((maximumOut - minimumOut) * (self - minimumIn) / (maximumIn - minimumIn)) + minimumOut
    }
}

extension CLLocation {
    fileprivate convenience init(_ coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}

extension Array where Element == CLLocationCoordinate2D {
    
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
