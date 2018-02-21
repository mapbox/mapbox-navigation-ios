import MapboxDirections
import Turf

extension RouteStep {
    static func ==(left: RouteStep, right: RouteStep) -> Bool {
        
        var finalHeading = false
        if let leftFinalHeading = left.finalHeading, let rightFinalHeading = right.finalHeading {
            finalHeading = leftFinalHeading == rightFinalHeading
        }
        
        let maneuverType = left.maneuverType == right.maneuverType
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
    
    /**
     Returns true if the current route step contains a tunnel.
     */
    var containsTunnel: Bool {
        guard let intersections = intersections else { return false }
        for intersection in intersections {
            if intersection.outletRoadClasses?.contains(.tunnel) == true {
                return true
            }
        }
        return false
    }
    
    /**
     Returns a tunnel slice for the current route step coordinates
     */
    var tunnelSlice: Polyline? {
        guard let coordinates = coordinates, let intersectionBounds = tunnelIntersectionBounds else { return nil }
        return Polyline(coordinates).sliced(from: intersectionBounds.entry.location, to: intersectionBounds.exit.location)
    }
    
    /**
     Returns the entry and exit intersection bounds of the tunnel on the current route step
     */
    var tunnelIntersectionBounds: (entry: Intersection, exit: Intersection)? {
        guard let intersections = intersections, intersections.count > 1, containsTunnel else { return nil }
        if let entryIndex = intersections.dropLast().index(where: { $0.outletRoadClasses?.contains(.tunnel) ?? false }) {
            return (entry: intersections[entryIndex], exit: intersections[intersections.index(after: entryIndex)])
        }
        return nil
    }
}
