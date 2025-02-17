import CoreLocation
import Foundation
import MapboxDirections
import MapboxNavigationNative

/// ``RouteLegProgress`` stores the user’s progress along a route leg.
public struct RouteLegProgress: Equatable, Sendable {
    // MARK: Details About the Leg

    mutating func update(using status: NavigationStatus) {
        guard let activeGuidanceInfo = status.activeGuidanceInfo else {
            return
        }

        let statusStepIndex = Int(status.stepIndex)
        guard leg.steps.indices ~= statusStepIndex else {
            Log.error("Incorrect step index update: \(statusStepIndex)", category: .navigation)
            return
        }

        if stepIndex == statusStepIndex {
            currentStepProgress.update(using: status)
        } else {
            var stepProgress = RouteStepProgress(step: leg.steps[statusStepIndex])
            stepProgress.update(using: status)
            currentStepProgress = stepProgress
        }

        stepIndex = statusStepIndex
        shapeIndex = Int(status.shapeIndex)

        currentSpeedLimit = nil
        if let speed = status.speedLimit.speed?.doubleValue {
            switch status.speedLimit.localeUnit {
            case .milesPerHour:
                currentSpeedLimit = Measurement(value: speed, unit: .milesPerHour)
            case .kilometresPerHour:
                currentSpeedLimit = Measurement(value: speed, unit: .kilometersPerHour)
            @unknown default:
                assertionFailure("Unknown native speed limit unit.")
            }
        }

        distanceTraveled = activeGuidanceInfo.legProgress.distanceTraveled
        durationRemaining = activeGuidanceInfo.legProgress.remainingDuration
        distanceRemaining = activeGuidanceInfo.legProgress.remainingDistance
        fractionTraveled = activeGuidanceInfo.legProgress.fractionTraveled

        if remainingSteps.count <= 2, status.routeState == .complete {
            userHasArrivedAtWaypoint = true
        }
    }

    /// Returns the current ``RouteLeg``.
    public private(set) var leg: RouteLeg

    /// Total distance traveled in meters along current leg.
    public private(set) var distanceTraveled: CLLocationDistance = 0

    /// Duration remaining in seconds on current leg.
    public private(set) var durationRemaining: TimeInterval = 0

    /// Distance remaining on the current leg.
    public private(set) var distanceRemaining: CLLocationDistance = 0

    /// Number between 0 and 1 representing how far along the current leg the user has traveled.
    public private(set) var fractionTraveled: Double = 0

    public var userHasArrivedAtWaypoint = false

    // MARK: Details About the Leg’s Steps

    /// Index representing the current step.
    public internal(set) var stepIndex: Int = 0

    /// The remaining steps for user to complete.
    public var remainingSteps: [RouteStep] {
        return Array(leg.steps.suffix(from: stepIndex + 1))
    }

    /// Returns the ``RouteStep`` before a given step. Returns `nil` if there is no step prior.
    public func stepBefore(_ step: RouteStep) -> RouteStep? {
        guard let index = leg.steps.firstIndex(of: step) else {
            return nil
        }
        if index > 0 {
            return leg.steps[index - 1]
        }
        return nil
    }

    /// Returns the ``RouteStep`` after a given step. Returns `nil` if there is not a step after.
    public func stepAfter(_ step: RouteStep) -> RouteStep? {
        guard let index = leg.steps.firstIndex(of: step) else {
            return nil
        }
        if index + 1 < leg.steps.endIndex {
            return leg.steps[index + 1]
        }
        return nil
    }

    /// Returns the ``RouteStep`` before the current step.
    ///
    /// If there is no ``priorStep``, `nil` is returned.
    public var priorStep: RouteStep? {
        guard stepIndex - 1 >= 0 else {
            return nil
        }
        return leg.steps[stepIndex - 1]
    }

    /// Returns the current ``RouteStep`` for the leg the user is on.
    public var currentStep: RouteStep {
        return leg.steps[stepIndex]
    }

    /// Returns the ``RouteStep`` after the current step.
    ///
    /// If there is no ``upcomingStep``, `nil` is returned.
    public var upcomingStep: RouteStep? {
        guard stepIndex + 1 < leg.steps.endIndex else {
            return nil
        }
        return leg.steps[stepIndex + 1]
    }

    /// Returns step 2 steps ahead.
    ///
    /// If there is no ``followOnStep``, `nil` is returned.
    public var followOnStep: RouteStep? {
        guard stepIndex + 2 < leg.steps.endIndex else {
            return nil
        }
        return leg.steps[stepIndex + 2]
    }

    /// Return bool whether step provided is the current ``RouteStep`` the user is on.
    public func isCurrentStep(_ step: RouteStep) -> Bool {
        return step == currentStep
    }

    /// Returns the progress along the current ``RouteStep``.
    public internal(set) var currentStepProgress: RouteStepProgress

    /// Returns the SpeedLimit for the current position along the route. Returns SpeedLimit.invalid if the speed limit
    /// is unknown or missing.
    ///
    /// The maximum speed may be an advisory speed limit for segments where legal limits are not posted, such as highway
    /// entrance and exit ramps. If the speed limit along a particular segment is unknown, it is set to `nil`. If the
    /// speed is unregulated along the segment, such as on the German _Autobahn_ system, it is represented by a
    /// measurement whose value is `Double.infinity`.
    ///
    /// Speed limit data is available in [a number of countries and territories
    /// worldwide](https://docs.mapbox.com/help/how-mapbox-works/directions/).
    public private(set) var currentSpeedLimit: Measurement<UnitSpeed>? = nil

    /// Index relative to leg shape, representing the point the user is currently located at.
    public private(set) var shapeIndex: Int = 0

    /// Intializes a new ``RouteLegProgress``.
    /// - Parameter leg: Leg on a ``NavigationRoute``.
    public init(leg: RouteLeg) {
        precondition(
            leg.steps.indices.contains(stepIndex),
            "It's not possible to set the stepIndex: \(stepIndex) when it's higher than steps count \(leg.steps.count) or not included."
        )

        self.leg = leg

        self.currentStepProgress = RouteStepProgress(step: leg.steps[stepIndex])
    }

    func refreshingLeg(with leg: RouteLeg) -> RouteLegProgress {
        var refreshedProgress = self

        refreshedProgress.leg = leg
        refreshedProgress.currentStepProgress = refreshedProgress.currentStepProgress
            .refreshingStep(with: leg.steps[stepIndex])

        return refreshedProgress
    }

    typealias StepIndexDistance = (index: Int, distance: CLLocationDistance)

    func closestStep(to coordinate: CLLocationCoordinate2D) -> StepIndexDistance? {
        var currentClosest: StepIndexDistance?
        let remainingSteps = leg.steps.suffix(from: stepIndex)

        for (currentStepIndex, step) in remainingSteps.enumerated() {
            guard let shape = step.shape else { continue }
            guard let closestCoordOnStep = shape.closestCoordinate(to: coordinate) else { continue }
            let closesCoordOnStepDistance = closestCoordOnStep.coordinate.distance(to: coordinate)
            let foundIndex = currentStepIndex + stepIndex

            // First time around, currentClosest will be `nil`.
            guard let currentClosestDistance = currentClosest?.distance else {
                currentClosest = (index: foundIndex, distance: closesCoordOnStepDistance)
                continue
            }

            if closesCoordOnStepDistance < currentClosestDistance {
                currentClosest = (index: foundIndex, distance: closesCoordOnStepDistance)
            }
        }

        return currentClosest
    }

    /// The waypoints remaining on the current leg, not including the leg’s destination.
    func remainingWaypoints(among waypoints: [MapboxDirections.Waypoint]) -> [MapboxDirections.Waypoint] {
        guard waypoints.count > 1 else {
            // The leg has only a source and no via points. Save ourselves a call to RouteLeg.coordinates, which can be
            // expensive.
            return []
        }
        let legPolyline = leg.shape
        guard let userCoordinateIndex = legPolyline.indexedCoordinateFromStart(distance: distanceTraveled)?.index else {
            // The leg is empty, so none of the waypoints are meaningful.
            return []
        }
        var slice = legPolyline
        var accumulatedCoordinates = 0
        return Array(waypoints.drop { waypoint -> Bool in
            let newSlice = slice.sliced(from: waypoint.coordinate)!
            accumulatedCoordinates += slice.coordinates.count - newSlice.coordinates.count
            slice = newSlice
            return accumulatedCoordinates <= userCoordinateIndex
        })
    }
}
