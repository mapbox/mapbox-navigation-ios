import MapboxDirections

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
     Returns true if the route travels on a motorway primarily identified by a route number rather than a road name.
     */
    var isNumberedMotorway: Bool {
        guard intersections?.first?.outletRoadClasses?.contains(.motorway) == true else {
            return false
        }
        guard let codes = codes, let digitRange = codes.first?.rangeOfCharacter(from: .decimalDigits) else {
            return false
        }
        return !digitRange.isEmpty
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
                return String.localizedStringWithFormat(NSLocalizedString("NAME_AND_REF", bundle: .mapboxCoreNavigation, value: "%@ (%@)", comment: "Format for speech string; 1 = way name; 2 = way route number"), nameSSML, codeSSML)
            } else {
                return nameSSML
            }
        }
        return nil
    }

}
