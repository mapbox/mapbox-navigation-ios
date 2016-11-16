//
//  MBNavigation.swift
//  MapboxNavigation
//
//  Created by Bobby Sudekum on 11/16/16.
//  Copyright © 2016 Mapbox. All rights reserved.
//

import Foundation
import MapboxDirections

public enum AlertLevel {
    case none
    case depart
    case low
    case medium
    case high
    case arrive
}

open class RouteProgress {
    public let route: Route
    public var legIndex: Int {
        didSet {
            assert(legIndex >= 0 && legIndex < route.legs.endIndex)
            // TODO: Set stepIndex to 0 or last index based on whether leg index was incremented or decremented.
            currentLegProgress = RouteLegProgress(leg: currentLeg)
        }
    }
    
    public var currentLeg: RouteLeg {
        return route.legs[legIndex]
    }
    
    public var distanceTraveled: CLLocationDistance {
        return route.legs.prefix(upTo: legIndex).map { $0.distance }.reduce(0, +) + currentLegProgress.distanceTraveled
    }
    
    public var durationRemaining: CLLocationDistance {
        return route.legs.suffix(from: legIndex + 1).map { $0.expectedTravelTime }.reduce(0, +) + currentLegProgress.durationRemaining
    }
    
    public var fractionTraveled: Double {
        return distanceTraveled / route.distance
    }
    
    public var distanceRemaining: CLLocationDistance {
        return route.distance - distanceTraveled
    }
    
    public var currentLegProgress: RouteLegProgress!
    
    public init(route: Route, legIndex: Int = 0) {
        self.route = route
        self.legIndex = legIndex
        currentLegProgress = RouteLegProgress(leg: currentLeg)
    }
}

open class RouteLegProgress {
    public let leg: RouteLeg
    public var stepIndex: Int {
        didSet {
            assert(stepIndex >= 0 && stepIndex < leg.steps.endIndex)
            currentStepProgress = RouteStepProgress(step: currentStep)
        }
    }
    
    public var distanceTraveled: CLLocationDistance {
        return leg.steps.prefix(upTo: stepIndex).map { $0.distance }.reduce(0, +) + currentStepProgress.distanceTraveled
    }
    
    public var durationRemaining: TimeInterval {
        return leg.steps.suffix(from: stepIndex + 1).map { $0.expectedTravelTime }.reduce(0, +) + currentStepProgress.durationRemaining
    }
    
    public var fractionTraveled: Double {
        return distanceTraveled / leg.distance
    }
    
    public var alertUserLevel: AlertLevel = .none
    
    public var currentStep: RouteStep {
        return leg.steps[stepIndex]
    }
    
    public var upComingStep: RouteStep? {
        guard stepIndex + 1 < leg.steps.endIndex else {
            return nil
        }
        return leg.steps[stepIndex + 1]
    }
    
    public var followOnStep: RouteStep? {
        guard stepIndex + 2 < leg.steps.endIndex else {
            return nil
        }
        return leg.steps[stepIndex + 2]
    }
    
    public func stepBefore(_ step: RouteStep) -> RouteStep? {
        guard let index = leg.steps.index(of: step) else {
            return nil
        }
        if index > 0 {
            return leg.steps[index-1]
        }
        return nil
    }
    
    public func stepAfter(_ step: RouteStep) -> RouteStep? {
        guard let index = leg.steps.index(of: step) else {
            return nil
        }
        if index+1 < leg.steps.endIndex {
            return leg.steps[index+1]
        }
        return nil
    }
    
    public func isCurrentStep(_ step: RouteStep) -> Bool {
        return leg.steps.index(of: step) == stepIndex
    }
    
    public var currentStepProgress: RouteStepProgress
    
    public init(leg: RouteLeg, stepIndex: Int = 0) {
        self.leg = leg
        self.stepIndex = stepIndex
        currentStepProgress = RouteStepProgress(step: leg.steps[stepIndex])
    }
}

open class RouteStepProgress {
    
    public let step: RouteStep
    public var distanceTraveled: CLLocationDistance = 0
    public var userDistanceToManeuverLocation: CLLocationDistance? = nil
    
    public var distanceRemaining: CLLocationDistance {
        return step.distance - distanceTraveled
    }
    
    public var fractionTraveled: Double {
        return distanceTraveled / step.distance
    }
    
    public var durationRemaining: TimeInterval {
        return (1 - fractionTraveled) * step.expectedTravelTime
    }
    
    public init(step: RouteStep) {
        self.step = step
    }
}
