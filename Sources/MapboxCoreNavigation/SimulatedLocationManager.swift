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
 */
open class SimulatedLocationManager: NavigationLocationManager {
    internal var currentDistance: CLLocationDistance = 0
    fileprivate var currentSpeed: CLLocationSpeed = 30
    fileprivate let accuracy: DispatchTimeInterval = .milliseconds(50)
    let updateInterval: DispatchTimeInterval = .milliseconds(1000)
    fileprivate var timer: DispatchTimer!
    
    fileprivate var locations: [SimulatedLocation]!
    fileprivate var routeShape: LineString!
    
    /**
     Specify the multiplier to use when calculating speed based on the RouteLeg’s `expectedSegmentTravelTimes`.
     */
    public var speedMultiplier: Double = 1
    fileprivate var simulatedLocation: CLLocation?
    override open var location: CLLocation? {
        get {
            return simulatedLocation
        }
        set {
            simulatedLocation = newValue
        }
    }
    
    var route: Route? {
        didSet {
            reset()
        }
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
    
    public override var simulatesLocation: Bool {
        get { return true }
        set { super.simulatesLocation = newValue }
    }
    
    private var routeProgress: RouteProgress?

    private let workingQueue: DispatchQueue

    public init(route: Route,
                currentDistance: CLLocationDistance,
                currentSpeed: CLLocationSpeed,
                workingQueue: DispatchQueue = .init(label: "com.mapbox.SimulatedLocationManager",
                                                    target: .global())) {
        self.route = route
        self.currentDistance = currentDistance
        self.currentSpeed = currentSpeed
        self.workingQueue = workingQueue
        super.init()
        commonInit()
    }

    /**
     Initalizes a new `SimulatedLocationManager` with the given route.
     
     - parameter route: The initial route.
     - returns: A `SimulatedLocationManager`
     */
    public convenience init(route: Route, workingQueue: DispatchQueue = .init(label: "com.mapbox.SimulatedLocationManager",
                                                                              target: .global())) {
        self.init(route: route, currentDistance: 0, currentSpeed: 30, workingQueue: workingQueue)
    }

    /**
     Initalizes a new `SimulatedLocationManager` with the given routeProgress.
     
     - parameter routeProgress: The routeProgress of the current route.
     - returns: A `SimulatedLocationManager`
     */
    public convenience init(routeProgress: RouteProgress, workingQueue: DispatchQueue = .global(qos: .default)) {
        let speed: CLLocationSpeed = 0
        self.init(route: routeProgress.route,
                  currentDistance: SimulatedLocationManager.currentDistance(startDistance: routeProgress.distanceTraveled,
                                                                            speed: speed,
                                                                            speedMultiplier: 1),
                  currentSpeed: speed,
                  workingQueue: workingQueue)
    }

    private func commonInit() {
        self.timer = DispatchTimer(countdown: .milliseconds(0),
                                   repeating: updateInterval,
                                   accuracy: accuracy,
                                   executingOn: workingQueue) { [weak self] in
            self?.tick()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReroute(_:)), name: .routeControllerDidReroute, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_:)), name: .routeControllerProgressDidChange, object: nil)
        reset()
    }
    
    private func reset() {
        if let shape = route?.shape {
            routeShape = shape
            locations = shape.coordinates.simulatedLocationsWithTurnPenalties()
        }
    }
    
    private func currentDistance(_ distance: CLLocationDistance) -> CLLocationDistance {
        return SimulatedLocationManager.currentDistance(startDistance: distance,
                                                        speed: currentSpeed,
                                                        speedMultiplier: speedMultiplier)
    }

    private static func currentDistance(startDistance: CLLocationDistance,
                                 speed: CLLocationSpeed,
                                 speedMultiplier: Double) -> CLLocationDistance {
        return startDistance + (speed * speedMultiplier)
    }
    
    @objc private func progressDidChange(_ notification: Notification) {
        routeProgress = notification.userInfo![RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
    }
    
    @objc private func didReroute(_ notification: Notification) {
        guard let router = notification.object as? Router else {
            return
        }

        self.currentDistance = currentDistance(router.routeProgress.distanceTraveled)
        routeProgress = router.routeProgress
        route = router.routeProgress.route
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .routeControllerDidReroute, object: nil)
        NotificationCenter.default.removeObserver(self, name: .routeControllerProgressDidChange, object: nil)
    }
    
    override open func startUpdatingLocation() {
        timer.arm()
    }
    
    override open func stopUpdatingLocation() {
        timer.disarm()
    }
    
    internal func tick() {
        let (routeShape, currentDistance, shape, expectedSegmentTravelTimes) = DispatchQueue.main.sync {
            (
                self.routeShape,
                self.currentDistance,
                self.routeProgress?.route.shape,
                routeProgress?.currentLeg.expectedSegmentTravelTimes
            )
        }
        guard let polyline = routeShape,
              let newCoordinate = polyline.coordinateFromStart(distance: currentDistance) else {
            return
        }
        
        // Closest coordinate ahead
        guard let lookAheadCoordinate = polyline.coordinateFromStart(distance: currentDistance + 10) else { return }
        guard let closestCoordinate = polyline.closestCoordinate(to: newCoordinate) else { return }
        
        let closestLocation = DispatchQueue.main.sync { self.locations[closestCoordinate.index] }
        let distanceToClosest = closestLocation.distance(from: CLLocation(newCoordinate))
        
        let distance = min(max(distanceToClosest, 10), safeDistance)
        let coordinatesNearby = polyline.trimmed(from: newCoordinate, distance: 100)!.coordinates

        let currentSpeed: CLLocationSpeed
        // Simulate speed based on expected segment travel time
        if let expectedSegmentTravelTimes = expectedSegmentTravelTimes,
            let shape = shape,
            let closestCoordinateOnRoute = shape.closestCoordinate(to: newCoordinate),
            let nextCoordinateOnRoute = shape.coordinates.after(element: shape.coordinates[closestCoordinateOnRoute.index]),
            let time = expectedSegmentTravelTimes.optional[closestCoordinateOnRoute.index] {
            let distance = shape.coordinates[closestCoordinateOnRoute.index].distance(to: nextCoordinateOnRoute)
            currentSpeed =  max(distance / time, 2)
        } else {
            currentSpeed = calculateCurrentSpeed(distance: distance, coordinatesNearby: coordinatesNearby, closestLocation: closestLocation)
        }
        
        let course = newCoordinate.direction(to: lookAheadCoordinate).wrap(min: 0, max: 360)

        DispatchQueue.main.async {
            let location = CLLocation(coordinate: newCoordinate,
                                      altitude: 0,
                                      horizontalAccuracy: horizontalAccuracy,
                                      verticalAccuracy: verticalAccuracy,
                                      course: course,
                                      speed: currentSpeed,
                                      timestamp: Date())
            self.currentSpeed = currentSpeed
            self.simulatedLocation = location
            self.delegate?.locationManager?(self, didUpdateLocations: [location])
            self.currentDistance = self.currentDistance(currentDistance)
        }
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
