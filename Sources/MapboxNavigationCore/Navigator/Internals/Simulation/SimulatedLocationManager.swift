import _MapboxNavigationHelpers
import Combine
import CoreLocation
import Foundation
import MapboxDirections
import Turf

private let maximumSpeed: CLLocationSpeed = 30 // ~108 kmh
private let minimumSpeed: CLLocationSpeed = 6 // ~21 kmh
private let verticalAccuracy: CLLocationAccuracy = 10
private let horizontalAccuracy: CLLocationAccuracy = 40
// minimumSpeed will be used when a location have maximumTurnPenalty
private let maximumTurnPenalty: CLLocationDirection = 90
// maximumSpeed will be used when a location have minimumTurnPenalty
private let minimumTurnPenalty: CLLocationDirection = 0
// Go maximum speed if distance to nearest coordinate is >= `safeDistance`
private let safeDistance: CLLocationDistance = 50

private class SimulatedLocation: CLLocation, @unchecked Sendable {
    var turnPenalty: Double = 0

    override var description: String {
        return "\(super.description) \(turnPenalty)"
    }
}

final class SimulatedLocationManager: NavigationLocationManager, @unchecked Sendable {
    @MainActor
    init(initialLocation: CLLocation?) {
        self.simulatedLocation = initialLocation

        super.init()

        restartTimer()
    }

    // MARK: Overrides

    override func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        realLocation = locations.last
    }

    // MARK: Specifying Simulation

    private func restartTimer() {
        let isArmed = timer?.state == .armed
        timer = DispatchTimer(
            countdown: .milliseconds(0),
            repeating: .milliseconds(updateIntervalMilliseconds / Int(speedMultiplier)),
            accuracy: accuracy,
            executingOn: queue
        ) { [weak self] in
            self?.tick()
        }
        if isArmed {
            timer.arm()
        }
    }

    var speedMultiplier: Double = 1 {
        didSet {
            restartTimer()
        }
    }

    override var location: CLLocation? {
        get {
            simulatedLocation ?? realLocation
        }
        set {
            simulatedLocation = newValue
        }
    }

    fileprivate var realLocation: CLLocation?
    fileprivate var simulatedLocation: CLLocation?

    override var simulatesLocation: Bool {
        get { return true }
        set { super.simulatesLocation = newValue }
    }

    override func startUpdatingLocation() {
        timer.arm()
        super.startUpdatingLocation()
    }

    override func stopUpdatingLocation() {
        timer.disarm()
        super.stopUpdatingLocation()
    }

    // MARK: Simulation Logic

    private var currentDistance: CLLocationDistance = 0
    private var currentSpeed: CLLocationSpeed = 0
    private let accuracy: DispatchTimeInterval = .milliseconds(50)
    private let updateIntervalMilliseconds: Int = 1000
    private let defaultTickInterval: TimeInterval = 1
    private var timer: DispatchTimer!
    private var locations: [SimulatedLocation]!
    private var remainingRouteShape: LineString!

    private let queue = DispatchQueue(label: "com.mapbox.SimulatedLocationManager")

    private(set) var route: Route?
    private var routeProgress: RouteProgress?

    private var _nextDate: Date?
    private func getNextDate() -> Date {
        if _nextDate == nil || _nextDate! < Date() {
            _nextDate = Date()
        } else {
            _nextDate?.addTimeInterval(defaultTickInterval)
        }
        return _nextDate!
    }

    private var slicedIndex: Int?

    private func update(route: Route?) {
        // NOTE: this method is expected to be called on the main thread, onMainQueueSync is used as extra check
        onMainAsync { [weak self] in
            self?.route = route
            if let shape = route?.shape {
                self?.queue.async { [shape, weak self] in
                    self?.reset(with: shape)
                }
            }
        }
    }

    private func reset(with shape: LineString?) {
        guard let shape else { return }

        remainingRouteShape = shape
        locations = shape.coordinates.simulatedLocationsWithTurnPenalties()
    }

    func tick() {
        let (
            expectedSegmentTravelTimes,
            originalShape
        ) = onMainQueueSync {
            (
                routeProgress?.currentLeg.expectedSegmentTravelTimes,
                route?.shape
            )
        }

        let tickDistance = currentSpeed * defaultTickInterval
        guard let remainingShape = remainingRouteShape,
              let originalShape,
              let indexedNewCoordinate = remainingShape.indexedCoordinateFromStart(distance: tickDistance)
        else {
            // report last known coordinate or real one
            if let simulatedLocation {
                self.simulatedLocation = .init(simulatedLocation: simulatedLocation, timestamp: getNextDate())
            } else if #available(iOS 15.0, *),
                      let realLocation,
                      let sourceInformation = realLocation.sourceInformation,
                      sourceInformation.isSimulatedBySoftware
            {
                // The location is simulated, we need to update timestamp
                self.realLocation = .init(
                    simulatedLocation: realLocation,
                    timestamp: getNextDate(),
                    sourceInformation: sourceInformation
                )
            }
            location.map { locationDelegate?.navigationLocationManager(self, didReceiveNewLocation: $0) }
            return
        }
        if remainingShape.distance() == 0,
           let routeDistance = originalShape.distance(),
           let lastCoordinate = originalShape.coordinates.last
        {
            currentDistance = routeDistance
            currentSpeed = 0

            let location = CLLocation(
                coordinate: lastCoordinate,
                altitude: 0,
                horizontalAccuracy: horizontalAccuracy,
                verticalAccuracy: verticalAccuracy,
                course: 0,
                speed: currentSpeed,
                timestamp: getNextDate()
            )
            onMainQueueSync { [weak self] in
                guard let self else { return }
                locationDelegate?.navigationLocationManager(self, didReceiveNewLocation: location)
            }

            return
        }

        let newCoordinate = indexedNewCoordinate.coordinate
        // Closest coordinate ahead
        guard let lookAheadCoordinate = remainingShape.coordinateFromStart(distance: tickDistance + 10) else { return }
        guard let closestCoordinateOnRouteIndex = slicedIndex.map({ idx -> Int? in
            originalShape.closestCoordinate(
                to: newCoordinate,
                startingIndex: idx
            )?.index
        }) ?? originalShape.closestCoordinate(to: newCoordinate)?.index else { return }

        // Simulate speed based on expected segment travel time
        if let expectedSegmentTravelTimes,
           let nextCoordinateOnRoute = originalShape.coordinates.after(index: closestCoordinateOnRouteIndex),
           let time = expectedSegmentTravelTimes.optional[closestCoordinateOnRouteIndex]
        {
            let distance = originalShape.coordinates[closestCoordinateOnRouteIndex].distance(to: nextCoordinateOnRoute)
            currentSpeed = min(max(distance / time, minimumSpeed), maximumSpeed)
            slicedIndex = max(closestCoordinateOnRouteIndex - 1, 0)
        } else {
            let closestLocation = locations[closestCoordinateOnRouteIndex]
            let distanceToClosest = closestLocation.distance(from: CLLocation(newCoordinate))
            let distance = min(max(distanceToClosest, 10), safeDistance)
            let coordinatesNearby = remainingShape.trimmed(from: newCoordinate, distance: 100)!.coordinates
            currentSpeed = calculateCurrentSpeed(
                distance: distance,
                coordinatesNearby: coordinatesNearby,
                closestLocation: closestLocation
            )
        }

        let location = CLLocation(
            coordinate: newCoordinate,
            altitude: 0,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            course: newCoordinate.direction(to: lookAheadCoordinate).wrap(min: 0, max: 360),
            speed: currentSpeed,
            timestamp: getNextDate()
        )

        simulatedLocation = location

        onMainQueueSync {
            locationDelegate?.navigationLocationManager(
                self,
                didReceiveNewLocation: location
            )
        }
        currentDistance += remainingShape.distance(to: newCoordinate) ?? 0
        remainingRouteShape = remainingShape.sliced(from: newCoordinate)
    }

    func progressDidChange(_ progress: RouteProgress?) {
        guard let progress else {
            cleanUp()
            return
        }
        onMainQueueSync {
            self.routeProgress = progress
            if progress.route.distance != self.route?.distance {
                update(route: progress.route)
            }
        }
    }

    func cleanUp() {
        route = nil
        routeProgress = nil
        remainingRouteShape = nil
        locations = []
    }

    func didReroute(progress: RouteProgress?) {
        guard let progress else { return }

        update(route: progress.route)

        let shape = progress.route.shape
        let currentSpeed = currentSpeed

        queue.async { [weak self] in
            guard let self,
                  let routeProgress else { return }

            var newClosestCoordinate: LocationCoordinate2D!
            if let location,
               let shape,
               let closestCoordinate = shape.closestCoordinate(to: location.coordinate)
            {
                simulatedLocation = location
                currentDistance = closestCoordinate.distance
                newClosestCoordinate = closestCoordinate.coordinate
            } else {
                currentDistance = calculateCurrentDistance(routeProgress.distanceTraveled, speed: currentSpeed)
                newClosestCoordinate = shape?.coordinateFromStart(distance: currentDistance)
            }

            onMainQueueSync {
                self.routeProgress = progress
                self.route = progress.route
            }
            reset(with: shape)
            remainingRouteShape = remainingRouteShape.sliced(from: newClosestCoordinate)
            slicedIndex = nil
        }
    }
}

// MARK: - Helpers

extension Double {
    fileprivate func scale(minimumIn: Double, maximumIn: Double, minimumOut: Double, maximumOut: Double) -> Double {
        return ((maximumOut - minimumOut) * (self - minimumIn) / (maximumIn - minimumIn)) + minimumOut
    }
}

extension CLLocation {
    fileprivate convenience init(_ coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }

    fileprivate convenience init(
        simulatedLocation: CLLocation,
        timestamp: Date
    ) {
        self.init(
            coordinate: simulatedLocation.coordinate,
            altitude: simulatedLocation.altitude,
            horizontalAccuracy: simulatedLocation.horizontalAccuracy,
            verticalAccuracy: simulatedLocation.verticalAccuracy,
            course: simulatedLocation.course,
            speed: simulatedLocation.speed,
            timestamp: timestamp
        )
    }

    @available(iOS 15.0, *)
    fileprivate convenience init(
        simulatedLocation: CLLocation,
        timestamp: Date,
        sourceInformation: CLLocationSourceInformation
    ) {
        self.init(
            coordinate: simulatedLocation.coordinate,
            altitude: simulatedLocation.altitude,
            horizontalAccuracy: simulatedLocation.horizontalAccuracy,
            verticalAccuracy: simulatedLocation.verticalAccuracy,
            course: simulatedLocation.course,
            courseAccuracy: simulatedLocation.courseAccuracy,
            speed: simulatedLocation.speed,
            speedAccuracy: simulatedLocation.speedAccuracy,
            timestamp: timestamp,
            sourceInfo: sourceInformation
        )
    }
}

extension Array where Element: Hashable {
    fileprivate struct OptionalSubscript {
        var elements: [Element]
        subscript(index: Int) -> Element? {
            return index < elements.count ? elements[index] : nil
        }
    }

    fileprivate var optional: OptionalSubscript { return OptionalSubscript(elements: self) }
}

extension Array where Element: Equatable {
    fileprivate func after(index: Index) -> Element? {
        if index + 1 < count {
            return self[index + 1]
        }
        return nil
    }
}

extension [CLLocationCoordinate2D] {
    // Calculate turn penalty for each coordinate.
    fileprivate func simulatedLocationsWithTurnPenalties() -> [SimulatedLocation] {
        var locations = [SimulatedLocation]()

        for (coordinate, nextCoordinate) in zip(prefix(upTo: endIndex - 1), suffix(from: 1)) {
            let currentCoordinate = locations.isEmpty ? first! : coordinate
            let course = coordinate.direction(to: nextCoordinate).wrap(min: 0, max: 360)
            let turnPenalty = currentCoordinate.direction(to: coordinate)
                .difference(from: coordinate.direction(to: nextCoordinate))
            let location = SimulatedLocation(
                coordinate: coordinate,
                altitude: 0,
                horizontalAccuracy: horizontalAccuracy,
                verticalAccuracy: verticalAccuracy,
                course: course,
                speed: minimumSpeed,
                timestamp: Date()
            )
            location.turnPenalty = Swift.max(Swift.min(turnPenalty, maximumTurnPenalty), minimumTurnPenalty)
            locations.append(location)
        }

        locations.append(SimulatedLocation(
            coordinate: last!,
            altitude: 0,
            horizontalAccuracy: horizontalAccuracy,
            verticalAccuracy: verticalAccuracy,
            course: locations.last!.course,
            speed: minimumSpeed,
            timestamp: Date()
        ))

        return locations
    }
}

extension LineString {
    fileprivate typealias DistanceIndex = (distance: LocationDistance, index: Int)

    fileprivate func closestCoordinate(to coordinate: LocationCoordinate2D, startingIndex: Int) -> DistanceIndex? {
        // Ported from https://github.com/Turfjs/turf/blob/142e137ce0c758e2825a260ab32b24db0aa19439/packages/turf-point-on-line/index.js
        guard let startCoordinate = coordinates.first,
              coordinates.indices.contains(startingIndex) else { return nil }

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
            let intersectionDistance: LocationDistance? = intersectionPoint != nil ? coordinate
                .distance(to: intersectionPoint!) : nil

            if distances.0 < closestDistance ?? .greatestFiniteMagnitude {
                closestCoordinate = (
                    distance: startCoordinate.distance(to: segment.0),
                    index: index
                )
                closestDistance = distances.0
            }
            if distances.1 < closestDistance ?? .greatestFiniteMagnitude {
                closestCoordinate = (
                    distance: startCoordinate.distance(to: segment.1),
                    index: index + 1
                )
                closestDistance = distances.1
            }
            if intersectionDistance != nil, intersectionDistance! < closestDistance ?? .greatestFiniteMagnitude {
                closestCoordinate = (
                    distance: startCoordinate.distance(to: intersectionPoint!),
                    index: index
                )
                closestDistance = intersectionDistance!
            }
        }

        return closestCoordinate
    }
}

private func calculateCurrentDistance(_ distance: CLLocationDistance, speed: CLLocationSpeed) -> CLLocationDistance {
    return distance + speed
}

private func calculateCurrentSpeed(
    distance: CLLocationDistance,
    coordinatesNearby: [CLLocationCoordinate2D]? = nil,
    closestLocation: SimulatedLocation
) -> CLLocationSpeed {
    // More than 10 nearby coordinates indicates that we are in a roundabout or similar complex shape.
    if let coordinatesNearby, coordinatesNearby.count >= 10 {
        return minimumSpeed
    }
    // Maximum speed if we are a safe distance from the closest coordinate
    else if distance >= safeDistance {
        return maximumSpeed
    }
    // Base speed on previous or upcoming turn penalty
    else {
        let reversedTurnPenalty = maximumTurnPenalty - closestLocation.turnPenalty
        return reversedTurnPenalty.scale(
            minimumIn: minimumTurnPenalty,
            maximumIn: maximumTurnPenalty,
            minimumOut: minimumSpeed,
            maximumOut: maximumSpeed
        )
    }
}
