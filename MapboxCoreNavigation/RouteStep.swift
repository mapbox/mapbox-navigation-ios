import MapboxDirections
import OSRMTextInstructions
import Turf

extension RouteStep {
    static func ==(left: RouteStep, right: RouteStep) -> Bool {
        
        var finalHeading = false
        if let leftFinalHeading = left.finalHeading, let rightFinalHeading = right.finalHeading {
            finalHeading = leftFinalHeading == rightFinalHeading
        }
        
        var maneuverType = false
        if let leftType = left.maneuverType, let rightType = right.maneuverType {
            maneuverType = leftType == rightType
        }
        
        let maneuverLocation = left.maneuverLocation == right.maneuverLocation
        
        return maneuverLocation && maneuverType && finalHeading
        
    }
    
    /**
     Returns true if the route step is on a motorway.
     */
    open var isMotorway: Bool {
        return intersections?.first?.outletRoadClasses?.contains(.motorway) ?? false
    }
    
    /**
     Returns true if the route travels on a motorway primarily identified by a route number rather than a road name.
     */
    var isNumberedMotorway: Bool {
        guard isMotorway else { return false }
        guard let codes = codes, let digitRange = codes.first?.rangeOfCharacter(from: .decimalDigits) else {
            return false
        }
        return !digitRange.isEmpty
    }
    
    /**
     Returns the last instruction for a given step.
     */
    open var lastInstruction: SpokenInstruction? {
        return instructionsSpokenAlongStep?.last
    }
}

extension CLLocation {
    /**
     Returns a Boolean value indicating whether the receiver is within a given distance of a route step, inclusive.
     */
    func isWithin(_ maximumDistance: CLLocationDistance, of routeStep: RouteStep) -> Bool {
        guard let closestCoordinate = Polyline(routeStep.coordinates!).closestCoordinate(to: coordinate) else {
            return false
        }
        return closestCoordinate.distance < maximumDistance
    }
}
