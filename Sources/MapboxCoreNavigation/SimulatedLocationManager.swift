import Foundation
import CoreLocation
import MapboxDirections
import Turf

fileprivate let maximumSpeed: CLLocationSpeed = 30 // ~108 kmh
fileprivate let minimumSpeed: CLLocationSpeed = 6 // ~21 kmh
fileprivate var distanceFilter: CLLocationDistance = 10
fileprivate var verticalAccuracy: CLLocationAccuracy = 10
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

 The manager calls delegate methods on a background thread.
 */
open class SimulatedLocationManager: NavigationLocationManager {
    
    /**
     Initalizes a new `SimulatedLocationManager` with the given route.
     
     - parameter route: The initial route.
     - returns: A `SimulatedLocationManager`
     */
    public init(route: Route) {
        super.init()
        commonInit(for: route, currentDistance: 0, currentSpeed: 0)
    }

    /**
     Initalizes a new `SimulatedLocationManager` with the given routeProgress.
     
     - parameter routeProgress: The routeProgress of the current route.
     - returns: A `SimulatedLocationManager`
     */
    public init(routeProgress: RouteProgress) {
        super.init()
        let currentDistance = calculateCurrentDistance(routeProgress.distanceTraveled)
        commonInit(for: routeProgress.route, currentDistance: currentDistance, currentSpeed: 0)
    }

    private func commonInit(for route: Route, currentDistance: CLLocationDistance, currentSpeed: CLLocationSpeed) {
        self.currentSpeed = currentSpeed
        self.currentDistance = currentDistance
        self.route = route
        if currentDistance != 0 {
            self.remainingRouteShape = route.shape?.trimmed(from: currentDistance, to: LocationDistance.infinity)
        }

        restartTimer()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReroute(_:)), name: .routeControllerDidReroute, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReroute(_:)), name: .routeControllerDidSwitchToCoincidentOnlineRoute, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_:)), name: .routeControllerProgressDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: nil)
    }
    
    // MARK: Specifying Simulation
    
    private func restartTimer() {
        let isArmed = timer?.state == .armed
        self.timer = DispatchTimer(countdown: .milliseconds(0),
                                   repeating: .milliseconds(updateIntervalMilliseconds / Int(speedMultiplier)),
                                   accuracy: accuracy,
                                   executingOn: queue) { [weak self] in
            self?.tick()
        }
        if isArmed {
            timer.arm()
        }
    }
    /**
     Specify the multiplier to use when calculating speed based on the RouteLeg’s `expectedSegmentTravelTimes`.
     
     - important: Change `speedMultiplier` only if you are doing start-to-finish simulation. If, at some point, sped up (or slowed down) simulated location updates will be mixed with real world updates - navigator map matching may become inadequate.
     */
    public var speedMultiplier: Double = 1 {
        didSet {
            restartTimer()
        }
    }
    override open var location: CLLocation? {
        get {
            return simulatedLocation
        }
        set {
            simulatedLocation = newValue
        }
    }
    
    fileprivate var simulatedLocation: CLLocation?
    
    public override var simulatesLocation: Bool {
        get { return true }
        set { super.simulatesLocation = newValue }
    }
    
    override open func startUpdatingLocation() {
        timer.arm()
    }
    
    override open func stopUpdatingLocation() {
        timer.disarm()
    }
    
    // MARK: Simulation Logic
    
    var currentDistance: CLLocationDistance = 0
    private var currentSpeed: CLLocationSpeed = 0
    private let accuracy: DispatchTimeInterval = .milliseconds(50)
    private let updateIntervalMilliseconds: Int = 1000
    private let defaultTickInterval: TimeInterval = 1
    private var timer: DispatchTimer!
    private var locations: [SimulatedLocation]!
    private var remainingRouteShape: LineString!

    private let queue = DispatchQueue(label: "com.mapbox.SimulatedLocationManager")
    
    var route: Route? {
        didSet {
            reset()
        }
    }
    
    private func reset() {
        if let shape = route?.shape {
            remainingRouteShape = shape
            locations = shape.coordinates.simulatedLocationsWithTurnPenalties()
        }
    }
    
    private var routeProgress: RouteProgress?
    
    private var _nextDate: Date? = nil
    private func getNextDate() -> Date {
        if _nextDate == nil || _nextDate! < Date() {
            _nextDate = Date()
        } else {
            _nextDate?.addTimeInterval(defaultTickInterval)
        }
        return _nextDate!
    }
    
    private var slicedIndex: Int? = nil
    
    internal func tick() {
        let tickDistance = currentSpeed * defaultTickInterval
        guard let remainingShape = remainingRouteShape,
              let originalShape = route?.shape,
              let indexedNewCoordinate = remainingShape.indexedCoordinateFromStart(distance: tickDistance) else {
            return
        }
        if remainingShape.distance() == 0,
           let routeDistance = originalShape.distance(),
           let lastCoordinate = originalShape.coordinates.last {
            currentDistance = routeDistance
            currentSpeed = 0
            
            let location = CLLocation(coordinate: lastCoordinate,
                                      altitude: 0,
                                      horizontalAccuracy: horizontalAccuracy,
                                      verticalAccuracy: verticalAccuracy,
                                      course: 0,
                                      speed: currentSpeed,
                                      timestamp: getNextDate())
            delegate?.locationManager?(self, didUpdateLocations: [location])
            
            return
        }
        
        let newCoordinate = indexedNewCoordinate.coordinate
        // Closest coordinate ahead
        guard let lookAheadCoordinate = remainingShape.coordinateFromStart(distance: tickDistance + 10) else { return }
        guard let closestCoordinateOnRouteIndex = slicedIndex.map({ idx -> Int? in
                  originalShape.closestCoordinate(to: newCoordinate,
                                                  startingIndex: idx)?.index
              }) ?? originalShape.closestCoordinate(to: newCoordinate)?.index else { return }
        
        // Simulate speed based on expected segment travel time
        if let expectedSegmentTravelTimes = routeProgress?.currentLeg.expectedSegmentTravelTimes,
           let nextCoordinateOnRoute = originalShape.coordinates.after(index: closestCoordinateOnRouteIndex),
           let time = expectedSegmentTravelTimes.optional[closestCoordinateOnRouteIndex] {
            let distance = originalShape.coordinates[closestCoordinateOnRouteIndex].distance(to: nextCoordinateOnRoute)
            currentSpeed =  min(max(distance / time, minimumSpeed), maximumSpeed)
            slicedIndex = max(closestCoordinateOnRouteIndex - 1, 0)
        } else {
            let closestLocation = locations[closestCoordinateOnRouteIndex]
            let distanceToClosest = closestLocation.distance(from: CLLocation(newCoordinate))
            let distance = min(max(distanceToClosest, 10), safeDistance)
            let coordinatesNearby = remainingShape.trimmed(from: newCoordinate, distance: 100)!.coordinates
            currentSpeed = calculateCurrentSpeed(distance: distance, coordinatesNearby: coordinatesNearby, closestLocation: closestLocation)
        }
        
        let location = CLLocation(coordinate: newCoordinate,
                                  altitude: 0,
                                  horizontalAccuracy: horizontalAccuracy,
                                  verticalAccuracy: verticalAccuracy,
                                  course: newCoordinate.direction(to: lookAheadCoordinate).wrap(min: 0, max: 360),
                                  speed: currentSpeed,
                                  timestamp: getNextDate())

        self.simulatedLocation = location

        delegate?.locationManager?(self, didUpdateLocations: [location])
        currentDistance += remainingShape.distance(to: newCoordinate) ?? 0
        
        remainingRouteShape = remainingShape.sliced(from: newCoordinate)
    }
    
    private func calculateCurrentSpeed(distance: CLLocationDistance, coordinatesNearby: [CLLocationCoordinate2D]? = nil, closestLocation: SimulatedLocation) -> CLLocationSpeed {
        // More than 10 nearby coordinates indicates that we are in a roundabout or similar complex shape.
        if let coordinatesNearby = coordinatesNearby, coordinatesNearby.count >= 10 {
            return minimumSpeed
        }
        // Maximum speed if we are a safe distance from the closest coordinate
        else if distance >= safeDistance {
            return maximumSpeed
        }
        // Base speed on previous or upcoming turn penalty
        else {
            let reversedTurnPenalty = maximumTurnPenalty - closestLocation.turnPenalty
            return reversedTurnPenalty.scale(minimumIn: minimumTurnPenalty, maximumIn: maximumTurnPenalty, minimumOut: minimumSpeed, maximumOut: maximumSpeed)
        }
    }
    
    private func calculateCurrentDistance(_ distance: CLLocationDistance) -> CLLocationDistance {
        return distance + currentSpeed
    }
    
    open override func copy() -> Any {
        let copy = SimulatedLocationManager(route: route!)
        copy.currentDistance = currentDistance
        copy.simulatedLocation = simulatedLocation
        copy.currentSpeed = currentSpeed
        copy.locations = locations
        copy.remainingRouteShape = remainingRouteShape
        copy.speedMultiplier = speedMultiplier
        
        copy.slicedIndex = slicedIndex
        return copy
    }
    
    @objc private func progressDidChange(_ notification: Notification) {
        routeProgress = notification.userInfo?[RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
    }
    
    @objc private func didReroute(_ notification: Notification) {
        queue.async { [self] in
            guard let router = notification.object as? Router else {
                return
            }
            
            var newClosestCoordinate: LocationCoordinate2D!
            if let location = notification.userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation,
               let shape = router.routeProgress.route.shape,
               let closestCoordinate = shape.closestCoordinate(to: location.coordinate) {
                simulatedLocation = location
                currentDistance = closestCoordinate.distance
                newClosestCoordinate = closestCoordinate.coordinate
            } else {
                currentDistance = calculateCurrentDistance(router.routeProgress.distanceTraveled)
                newClosestCoordinate = router.routeProgress.route.shape?.coordinateFromStart(distance: currentDistance)
            }
            
            routeProgress = router.routeProgress
            route = router.routeProgress.route
            
            remainingRouteShape = remainingRouteShape.sliced(from: newClosestCoordinate)
            slicedIndex = nil
        }
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

extension Array where Element : Hashable {
    fileprivate struct OptionalSubscript {
        var elements: [Element]
        subscript (index: Int) -> Element? {
            return index < elements.count ? elements[index] : nil
        }
    }
    
    fileprivate var optional: OptionalSubscript {
        get { return OptionalSubscript(elements: self) }
    }
}

extension Array where Element : Equatable {
    fileprivate func after(index: Index) -> Element? {
        if index + 1 < self.count {
            return self[index + 1]
        }
        return nil
    }
}

extension Array where Element == CLLocationCoordinate2D {
    // Calculate turn penalty for each coordinate.
    fileprivate func simulatedLocationsWithTurnPenalties() -> [SimulatedLocation] {
        var locations = [SimulatedLocation]()
        
        for (coordinate, nextCoordinate) in zip(prefix(upTo: endIndex - 1), suffix(from: 1)) {
            let currentCoordinate = locations.isEmpty ? first! : coordinate
            let course = coordinate.direction(to: nextCoordinate).wrap(min: 0, max: 360)
            let turnPenalty = currentCoordinate.direction(to: coordinate).difference(from: coordinate.direction(to: nextCoordinate))
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

fileprivate extension LineString {
    typealias DistanceIndex = (distance: LocationDistance, index: Int)
    
    func closestCoordinate(to coordinate: LocationCoordinate2D, startingIndex: Int) -> DistanceIndex? {
        // Ported from https://github.com/Turfjs/turf/blob/142e137ce0c758e2825a260ab32b24db0aa19439/packages/turf-point-on-line/index.js
        guard let startCoordinate = coordinates.first else { return nil }
        
        guard coordinates.count > 1 else {
            return (coordinate.distance(to: startCoordinate), 0)
        }
        
        var closestCoordinate: DistanceIndex?
        var closestDistance: LocationDistance?
        
        for index in startingIndex..<coordinates.count - 1 {
            let segment = (coordinates[index], coordinates[index + 1])
            let distances = (coordinate.distance(to: segment.0), coordinate.distance(to: segment.1))
            
            let maxDistance = max(distances.0, distances.1)
            let direction = segment.0.direction(to: segment.1)
            let perpendicularPoint1 = coordinate.coordinate(at: maxDistance, facing: direction + 90)
            let perpendicularPoint2 = coordinate.coordinate(at: maxDistance, facing: direction - 90)
            let intersectionPoint = Turf.intersection((perpendicularPoint1, perpendicularPoint2), segment)
            let intersectionDistance: LocationDistance? = intersectionPoint != nil ? coordinate.distance(to: intersectionPoint!) : nil
            
            if distances.0 < closestDistance ?? .greatestFiniteMagnitude {
                closestCoordinate = (distance: startCoordinate.distance(to: segment.0),
                                     index: index)
                closestDistance = distances.0
            }
            if distances.1 < closestDistance ?? .greatestFiniteMagnitude {
                closestCoordinate = (distance: startCoordinate.distance(to: segment.1),
                                     index: index+1)
                closestDistance = distances.1
            }
            if intersectionDistance != nil && intersectionDistance! < closestDistance ?? .greatestFiniteMagnitude {
                closestCoordinate = (distance: startCoordinate.distance(to: intersectionPoint!),
                                     index: index)
                closestDistance = intersectionDistance!
            }
        }
        
        return closestCoordinate
    }
}
