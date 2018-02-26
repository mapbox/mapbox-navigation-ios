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
     Returns an array of the tunnel intersection bounds on the current route step.
     */
    var tunnelIntersectionBounds: [IntersectionBounds]? {
        guard let coordinates = coordinates, let intersections = intersections, containsTunnel else { return nil }
        var intersectionBounds = [IntersectionBounds]()
        for i in 0..<intersections.count {
            if let outletRoadClasses = intersections[i].outletRoadClasses, outletRoadClasses.contains(.tunnel) && i < intersections.count - 1 {
                let bounds = IntersectionBounds(intersections[i], intersections[i+1], coordinates)
                intersectionBounds.append(bounds)
            }
        }
        return intersectionBounds
    }
    
}

public struct IntersectionBounds {
    let entry: Intersection
    let exit: Intersection
    let polyline: Polyline
    let distanceToEntry: CLLocationDistance
    let distanceToExit: CLLocationDistance
    
    public init(_ entry: Intersection, _ exit: Intersection, _ coordinates: [CLLocationCoordinate2D]) {
        self.entry = entry
        self.exit = exit
        polyline = Polyline(coordinates)
        distanceToEntry = polyline.distance(from: coordinates.first, to: entry.location)
        distanceToExit = polyline.distance(from: coordinates.first, to: exit.location)
    }
}
