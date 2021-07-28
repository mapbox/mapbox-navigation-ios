import Foundation
import CoreLocation
import MapboxDirections
import Turf

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
    /// :nodoc:
    public struct Configuration {
        public var maximumSpeed: CLLocationSpeed
        public var minimumSpeed: CLLocationSpeed
        public var distanceFilter: CLLocationDistance
        public var verticalAccuracy: CLLocationAccuracy
        public var horizontalAccuracy: CLLocationAccuracy
        /// `minimumSpeed` will be used when a location have `maximumTurnPenalty`.
        public var maximumTurnPenalty: CLLocationDirection
        // `maximumSpeed` will be used when a location have `minimumTurnPenalty`
        public var minimumTurnPenalty: CLLocationDirection
        // Go with maximum speed if the distance to the nearest coordinate is >= `safeDistance`
        public var safeDistance: CLLocationDistance

        public static var `default`: Configuration {
            .init(
                maximumSpeed: 30, // ~108 km/h
                minimumSpeed: 6, // ~21 km/h
                distanceFilter: 10,
                verticalAccuracy: 10,
                horizontalAccuracy: 40,
                maximumTurnPenalty: 90,
                minimumTurnPenalty: 0,
                safeDistance: 50
            )
        }
    }

    /// :nodoc:
    public static var defaultQueue: DispatchQueue {
        .init(label: "com.mapbox.SimulatedLocationManager", target: .global())
    }

    private let configuration: Configuration

    internal var currentDistance: CLLocationDistance
    private var currentSpeed: CLLocationSpeed
    private let accuracy: DispatchTimeInterval = .milliseconds(50)
    private let updateInterval: DispatchTimeInterval = .milliseconds(1000)
    private let queue: DispatchQueue
    private var timer: DispatchTimer!
    
    private var locations: [SimulatedLocation] = []
    private var routeShape: LineString?
    
    /**
     Specify the multiplier to use when calculating speed based on the RouteLeg’s `expectedSegmentTravelTimes`.
     */
    public var speedMultiplier: Double = 1
    private var simulatedLocation: CLLocation?
    
    override open var location: CLLocation? {
        get {
            return simulatedLocation
        }
        set {
            simulatedLocation = newValue
        }
    }

    var route: Route {
        didSet {
            reset()
        }
    }
    
    open override func copy() -> Any {
        let copy = SimulatedLocationManager(route: route, currentDistance: currentDistance, currentSpeed: currentSpeed)
        copy.simulatedLocation = simulatedLocation
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
    
    /**
     Initalizes a new `SimulatedLocationManager` with the given route.
     
     - parameter route: The initial route.
     - parameter queue: A GCD queue which is used to calculate simulated locations.
     - returns: A `SimulatedLocationManager`
     */
    public convenience init(route: Route, configuration: Configuration = .default, queue: DispatchQueue = defaultQueue) {
        self.init(route: route, currentDistance: 0, currentSpeed: 30, configuration: configuration, queue: queue)
    }

    /**
     Initalizes a new `SimulatedLocationManager` with the given routeProgress.
     
     - parameter routeProgress: The routeProgress of the current route.
     - parameter queue: A GCD queue which is used to calculate simulated locations.
     - returns: A `SimulatedLocationManager`
     */
    public convenience init(routeProgress: RouteProgress, configuration: Configuration = .default, queue: DispatchQueue = defaultQueue) {
        let currentSpeed: CLLocationSpeed = 0
        let currentDistance = Self.calculateCurrentDistance(routeProgress.distanceTraveled,
                                                            currentSpeed: currentSpeed,
                                                            speedMultiplier: 1)
        self.init(route: routeProgress.route, currentDistance: currentDistance, currentSpeed: currentSpeed, configuration: configuration, queue: queue)
    }

    /**
     Initalizes a new `SimulatedLocationManager` instance with the given route and initial state.
     - Parameters:
       - route: The initial route.
       - currentDistance: The initial distance from the beginning of the route.
       - currentSpeed: The initial speed of the simulation.
       - queue: A GCD queue which is used to calculate simulated locations.
     */
    public init(route: Route, currentDistance: CLLocationDistance, currentSpeed: CLLocationSpeed, configuration: Configuration = .default, queue: DispatchQueue = defaultQueue) {
        self.route = route
        self.currentDistance = currentDistance
        self.currentSpeed = currentSpeed
        self.configuration = configuration
        self.queue = queue
        super.init()
        postInit()
    }

    private func postInit() {
        reset()

        self.timer = DispatchTimer(countdown: .milliseconds(0),
                                   repeating: updateInterval,
                                   accuracy: accuracy,
                                   executingOn: queue) { [weak self] in
            self?.tick()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(didReroute(_:)),
                                               name: .routeControllerDidReroute, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(progressDidChange(_:)),
                                               name: .routeControllerProgressDidChange, object: nil)
    }
    
    private func reset() {
        guard let shape = route.shape else { return }
        routeShape = shape
        locations = shape.coordinates.simulatedLocationsWithTurnPenalties(configuration: configuration)
    }
    
    private static func calculateCurrentDistance(_ distance: CLLocationDistance,
                                                 currentSpeed: CLLocationSpeed,
                                                 speedMultiplier: Double) -> CLLocationDistance {
        return distance + (currentSpeed * speedMultiplier)
    }
    
    @objc private func progressDidChange(_ notification: Notification) {
        routeProgress = notification.userInfo![RouteController.NotificationUserInfoKey.routeProgressKey] as? RouteProgress
    }
    
    @objc private func didReroute(_ notification: Notification) {
        guard let router = notification.object as? Router else {
            return
        }

        self.currentDistance = Self.calculateCurrentDistance(router.routeProgress.distanceTraveled,
                                                             currentSpeed: currentSpeed,
                                                             speedMultiplier: speedMultiplier)
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
        let (routeShape, currentDistance, shape, expectedSegmentTravelTimes, speedMultiplier, configuration) = DispatchQueue.main.sync {
                    (
                        self.routeShape,
                        self.currentDistance,
                        self.routeProgress?.route.shape,
                        self.routeProgress?.currentLeg.expectedSegmentTravelTimes,
                        self.speedMultiplier,
                        self.configuration
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
        
        let distance = min(max(distanceToClosest, 10), configuration.safeDistance)
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
            currentSpeed = calculateCurrentSpeed(distance: distance,
                                                 coordinatesNearby: coordinatesNearby,
                                                 closestLocation: closestLocation)
        }

        let course = newCoordinate.direction(to: lookAheadCoordinate).wrap(min: 0, max: 360)
        DispatchQueue.main.async {
            let location = CLLocation(coordinate: newCoordinate,
                                      altitude: 0,
                                      horizontalAccuracy: configuration.horizontalAccuracy,
                                      verticalAccuracy: configuration.verticalAccuracy,
                                      course: course,
                                      speed: currentSpeed,
                                      timestamp: Date())
            self.currentSpeed = currentSpeed
            self.simulatedLocation = location
            self.delegate?.locationManager?(self, didUpdateLocations: [location])
            self.currentDistance = Self.calculateCurrentDistance(currentDistance,
                                                                 currentSpeed: currentSpeed,
                                                                 speedMultiplier: speedMultiplier)
        }
    }
    
    private func calculateCurrentSpeed(distance: CLLocationDistance,
                                       coordinatesNearby: [CLLocationCoordinate2D]? = nil,
                                       closestLocation: SimulatedLocation) -> CLLocationSpeed {
        // More than 10 nearby coordinates indicates that we are in a roundabout or similar complex shape.
        if let coordinatesNearby = coordinatesNearby, coordinatesNearby.count >= 10 {
            return configuration.minimumSpeed
        }
        // Maximum speed if we are a safe distance from the closest coordinate
        else if distance >= configuration.safeDistance {
            return configuration.maximumSpeed
        }
        // Base speed on previous or upcoming turn penalty
        else {
            let reversedTurnPenalty = configuration.maximumTurnPenalty - closestLocation.turnPenalty
            return reversedTurnPenalty.scale(minimumIn: configuration.minimumTurnPenalty,
                                             maximumIn: configuration.maximumTurnPenalty,
                                             minimumOut: configuration.minimumSpeed,
                                             maximumOut: configuration.maximumSpeed)
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
    fileprivate func simulatedLocationsWithTurnPenalties(configuration: SimulatedLocationManager.Configuration) -> [SimulatedLocation] {
        var locations = [SimulatedLocation]()
        
        for (coordinate, nextCoordinate) in zip(prefix(upTo: endIndex - 1), suffix(from: 1)) {
            let currentCoordinate = locations.isEmpty ? first! : coordinate
            let course = coordinate.direction(to: nextCoordinate).wrap(min: 0, max: 360)
            let turnPenalty = currentCoordinate
                .direction(to: coordinate)
                .difference(from: coordinate.direction(to: nextCoordinate))
            let location = SimulatedLocation(coordinate: coordinate,
                                             altitude: 0,
                                             horizontalAccuracy: configuration.horizontalAccuracy,
                                             verticalAccuracy: configuration.verticalAccuracy,
                                             course: course,
                                             speed: configuration.minimumSpeed,
                                             timestamp: Date())
            location.turnPenalty = Swift.max(Swift.min(turnPenalty, configuration.maximumTurnPenalty), configuration.minimumTurnPenalty)
            locations.append(location)
        }
        
        locations.append(SimulatedLocation(coordinate: last!,
                                           altitude: 0,
                                           horizontalAccuracy: configuration.horizontalAccuracy,
                                           verticalAccuracy: configuration.verticalAccuracy,
                                           course: locations.last!.course,
                                           speed: configuration.minimumSpeed,
                                           timestamp: Date()))
        
        return locations
    }
}
