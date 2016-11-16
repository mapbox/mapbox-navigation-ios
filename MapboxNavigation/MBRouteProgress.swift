//
//  MBNavigation.swift
//  MapboxNavigation
//
//  Created by Bobby Sudekum on 11/16/16.
//  Copyright © 2016 Mapbox. All rights reserved.
//

import Foundation
import MapboxDirections

enum AlertLevel {
    case none
    case depart
    case low
    case medium
    case high
    case arrive
}

class RouteProgress {
    let route: Route
    var legIndex: Int {
        didSet {
            assert(legIndex >= 0 && legIndex < route.legs.endIndex)
            // TODO: Set stepIndex to 0 or last index based on whether leg index was incremented or decremented.
            currentLegProgress = RouteLegProgress(leg: currentLeg)
        }
    }
    
    var currentLeg: RouteLeg {
        return route.legs[legIndex]
    }
    
    var distanceTraveled: CLLocationDistance {
        return route.legs.prefix(upTo: legIndex).map { $0.distance }.reduce(0, +) + currentLegProgress.distanceTraveled
    }
    
    var durationRemaining: CLLocationDistance {
        return route.legs.suffix(from: legIndex + 1).map { $0.expectedTravelTime }.reduce(0, +) + currentLegProgress.durationRemaining
    }
    
    var fractionTraveled: Double {
        return distanceTraveled / route.distance
    }
    
    var distanceRemaining: CLLocationDistance {
        return route.distance - distanceTraveled
    }
    
    var currentLegProgress: RouteLegProgress!
    
    init(route: Route, legIndex: Int = 0) {
        self.route = route
        self.legIndex = legIndex
        currentLegProgress = RouteLegProgress(leg: currentLeg)
    }
}

class RouteLegProgress {
    let leg: RouteLeg
    var stepIndex: Int {
        didSet {
            assert(stepIndex >= 0 && stepIndex < leg.steps.endIndex)
            currentStepProgress = RouteStepProgress(step: currentStep)
        }
    }
    
    var distanceTraveled: CLLocationDistance {
        return leg.steps.prefix(upTo: stepIndex).map { $0.distance }.reduce(0, +) + currentStepProgress.distanceTraveled
    }
    
    var durationRemaining: TimeInterval {
        return leg.steps.suffix(from: stepIndex + 1).map { $0.expectedTravelTime }.reduce(0, +) + currentStepProgress.durationRemaining
    }
    
    var fractionTraveled: Double {
        return distanceTraveled / leg.distance
    }
    
    var alertUserLevel: AlertLevel = .none
    
    var currentStep: RouteStep {
        return leg.steps[stepIndex]
    }
    
    var upComingStep: RouteStep? {
        guard stepIndex + 1 < leg.steps.endIndex else {
            return nil
        }
        return leg.steps[stepIndex + 1]
    }
    
    var followOnStep: RouteStep? {
        guard stepIndex + 2 < leg.steps.endIndex else {
            return nil
        }
        return leg.steps[stepIndex + 2]
    }
    
    func stepBefore(_ step: RouteStep) -> RouteStep? {
        guard let index = leg.steps.index(of: step) else {
            return nil
        }
        if index > 0 {
            return leg.steps[index-1]
        }
        return nil
    }
    
    func stepAfter(_ step: RouteStep) -> RouteStep? {
        guard let index = leg.steps.index(of: step) else {
            return nil
        }
        if index+1 < leg.steps.endIndex {
            return leg.steps[index+1]
        }
        return nil
    }
    
    func isCurrentStep(_ step: RouteStep) -> Bool {
        return leg.steps.index(of: step) == stepIndex
    }
    
    var currentStepProgress: RouteStepProgress
    
    init(leg: RouteLeg, stepIndex: Int = 0) {
        self.leg = leg
        self.stepIndex = stepIndex
        currentStepProgress = RouteStepProgress(step: leg.steps[stepIndex])
    }
}

class RouteStepProgress {
    
    let step: RouteStep
    var distanceTraveled: CLLocationDistance = 0
    var userDistanceToManeuverLocation: CLLocationDistance? = nil
    
    var distanceRemaining: CLLocationDistance {
        return step.distance - distanceTraveled
    }
    
    var fractionTraveled: Double {
        return distanceTraveled / step.distance
    }
    
    var durationRemaining: TimeInterval {
        return (1 - fractionTraveled) * step.expectedTravelTime
    }
    
    init(step: RouteStep) {
        self.step = step
    }
}
