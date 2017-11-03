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
    
    /**
     Returns a string describing the step’s road by its name, route number, or both, depending on the kind of road.
     
     - parameter markedUpWithSSML: True to wrap the name and route number in SSML tags that cause them to be read as addresses.
     - returns: A string describing the step’s road, or `nil` if the step lacks the information needed to describe the step.
     */
    public func roadDescription(markedUpWithSSML: Bool) -> String? {
        let addressSSML = { (text: String?) -> String? in
            guard let text = text else {
                return nil
            }
            return markedUpWithSSML ? "<say-as interpret-as=\"address\">\(text.addingXMLEscapes)</say-as>" : text
        }
        
        let nameSSML = addressSSML(names?.first)
        let codeSSML = addressSSML(codes?.first)
        
        if let codeSSML = codeSSML, nameSSML == nil || isNumberedMotorway {
            return codeSSML
        } else if let nameSSML = nameSSML {
            if let codeSSML = codeSSML {
                let phrase = RouteStepFormatter().instructions.phrase(named: .nameWithCode)
                return phrase.replacingTokens { (tokenType) -> String in
                    switch tokenType {
                    case .wayName:
                        return nameSSML
                    case .code:
                        return codeSSML
                    default:
                        fatalError("Unexpected token \(tokenType)")
                    }
                }
            } else {
                return nameSSML
            }
        }
        return nil
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
