import Foundation
import MapboxDirections
import OSRMTextInstructions

@objc(MBRouteStepFormatter)
public class RouteStepFormatter: Formatter {
    let instructions = OSRMInstructionFormatter(version: "v5")
    
    /**
     Return an instruction as a `String`.
     */
    public override func string(for obj: Any?) -> String? {
        return string(for: obj, legIndex: nil, numberOfLegs: nil, markUpWithSSML: false)
    }
    
    /**
     Returns an instruction as a `String`. Setting `markUpWithSSML` to `true` will return a string containing [SSML](https://www.w3.org/TR/speech-synthesis/) tag information around appropriate strings.
     */
    public func string(for obj: Any?, legIndex: Int?, numberOfLegs: Int?, markUpWithSSML: Bool) -> String? {
        guard let step = obj as? RouteStep else {
            return nil
        }
        
        let modifyValueByKey = { (key: OSRMTextInstructions.TokenType, value: String) -> String in
            switch key {
            case .wayName, .destination, .rotaryName:
                return "<say-as interpret-as=\"address\">\(value.addingXMLEscapes)</say-as>"
            default:
                return value
            }
        }
        
        return instructions.string(for: step, legIndex: legIndex, numberOfLegs: numberOfLegs, roadClasses: step.intersections?.first?.outletRoadClasses, modifyValueByKey: markUpWithSSML ? modifyValueByKey : nil)
        
    }
    
    public override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        return false
    }
}

extension RouteStep {
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
    func roadDescription(markedUpWithSSML: Bool) -> String? {
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
                return String.localizedStringWithFormat(NSLocalizedString("NAME_AND_REF", bundle: .mapboxNavigation, value: "%@ (%@)", comment: "Format for speech string; 1 = way name; 2 = way route number"), nameSSML, codeSSML)
            } else {
                return nameSSML
            }
        }
        return nil
    }
}
