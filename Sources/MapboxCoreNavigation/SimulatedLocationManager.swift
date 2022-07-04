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
        commonInit(for: route, currentDistance: 0, currentSpeed: 30)
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

        restartTimer()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReroute(_:)), name: .routeControllerDidReroute, object: nil)
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
    private var currentSpeed: CLLocationSpeed = 30
    private let accuracy: DispatchTimeInterval = .milliseconds(50)
    private let updateIntervalMilliseconds: Int = 1000
    private var timer: DispatchTimer!
    private var locations: [SimulatedLocation]!
    private var routeShape: LineString!

    private let queue = DispatchQueue(label: "com.mapbox.SimulatedLocationManager")
    
    var route: Route? {
        didSet {
            reset()
        }
    }
    
    private func reset() {
        if let shape = route?.shape {
            routeShape = shape
            locations = shape.coordinates.simulatedLocationsWithTurnPenalties()
        }
    }
    
    private var routeProgress: RouteProgress?
    
    private var _nextDate: Date? = nil
    private func getNextDate() -> Date {
        if _nextDate == nil || _nextDate! < Date() {
            _nextDate = Date()
        } else {
            _nextDate?.addTimeInterval(1)
        }
        return _nextDate!
    }
    
    internal func tick() {
        guard let polyline = routeShape,
              let newCoordinate = polyline.coordinateFromStart(distance: currentDistance) else {
            return
        }
        
        // Closest coordinate ahead
        guard let lookAheadCoordinate = polyline.coordinateFromStart(distance: currentDistance + 10) else { return }
        guard let closestCoordinate = polyline.closestCoordinate(to: newCoordinate) else { return }
        
        // Simulate speed based on expected segment travel time
        if let expectedSegmentTravelTimes = routeProgress?.currentLeg.expectedSegmentTravelTimes,
            let closestCoordinateOnRoute = polyline.closestCoordinate(to: newCoordinate),
            let nextCoordinateOnRoute = polyline.coordinates.after(element: polyline.coordinates[closestCoordinateOnRoute.index]),
            let time = expectedSegmentTravelTimes.optional[closestCoordinateOnRoute.index] {
            let distance = polyline.coordinates[closestCoordinateOnRoute.index].distance(to: nextCoordinateOnRoute)
            currentSpeed =  min(max(distance / time, minimumSpeed), maximumSpeed)
        } else {
            let closestLocation = locations[closestCoordinate.index]
            let distanceToClosest = closestLocation.distance(from: CLLocation(newCoordinate))
            let distance = min(max(distanceToClosest, 10), safeDistance)
            let coordinatesNearby = polyline.trimmed(from: newCoordinate, distance: 100)!.coordinates
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
        currentDistance = calculateCurrentDistance(currentDistance)
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
        copy.routeShape = routeShape
        copy.speedMultiplier = speedMultiplier
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
            
            if let location = notification.userInfo?[RouteController.NotificationUserInfoKey.locationKey] as? CLLocation,
               let shape = router.routeProgress.route.shape,
               let closestCoordinate = shape.closestCoordinate(to: location.coordinate) {
                simulatedLocation = location
                currentDistance = closestCoordinate.distance
            } else {
                currentDistance = calculateCurrentDistance(router.routeProgress.distanceTraveled)
            }
            
            routeProgress = router.routeProgress
            route = router.routeProgress.route
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
    fileprivate func after(element: Element) -> Element? {
        if let index = self.firstIndex(of: element), index + 1 <= self.count {
            return index + 1 == self.count ? self[0] : self[index + 1]
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
